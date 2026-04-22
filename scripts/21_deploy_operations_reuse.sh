#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd jq
require_cmd curl
require_cmd expect
require_cmd ssh
require_cmd scp
require_cmd openssl

load_local_env

NAMESPACE="${NAMESPACE:-default}"
SAM_API_BASE_URL="${SAM_API_BASE_URL:-http://192.168.32.100/api/v1}"
PROJECT_FILE="${PROJECT_FILE:-$ROOT_DIR/deploy/rfq/operations-reuse-project-template.json}"
RBAC_FILE="${RBAC_FILE:-$ROOT_DIR/deploy/rfq/operations-reuse-rbac.yaml}"
PG_RELEASE="${PG_RELEASE:-rfq-postgresql}"
PG_SERVICE="${PG_SERVICE:-rfq-postgresql}"
PG_PORT="${PG_PORT:-5432}"
DB_USER_SECRET="${DB_USER_SECRET:-operations-reuse-db-users}"

REPLENISHMENT_RELEASE="${REPLENISHMENT_RELEASE:-replenishment-planner-agent}"
REPLENISHMENT_VALUES="${REPLENISHMENT_VALUES:-$ROOT_DIR/deploy/rfq/replenishment-planner-agent-values.generated.yaml}"
REPLENISHMENT_CONFIG="${REPLENISHMENT_CONFIG:-$ROOT_DIR/deploy/rfq/replenishment-planner-agent-config.yaml}"

TRIAGE_RELEASE="${TRIAGE_RELEASE:-order-exception-triage-agent}"
TRIAGE_VALUES="${TRIAGE_VALUES:-$ROOT_DIR/deploy/rfq/order-exception-triage-agent-values.generated.yaml}"
TRIAGE_CONFIG="${TRIAGE_CONFIG:-$ROOT_DIR/deploy/rfq/order-exception-triage-agent-config.yaml}"

if [[ ! -f "$PROJECT_FILE" ]]; then
  log "Project file not found: $PROJECT_FILE"
  exit 1
fi

if [[ ! -f "$RBAC_FILE" ]]; then
  log "RBAC file not found: $RBAC_FILE"
  exit 1
fi

get_remote_secret_value() {
  local secret_name="$1"
  local key="$2"
  run_remote "kubectl get secret $secret_name -n $NAMESPACE -o jsonpath='{.data.$key}' | base64 -d"
}

ensure_ops_databases() {
  local pg_admin_password replenishment_user replenishment_pass triage_user triage_pass
  local bootstrap_sql

  pg_admin_password="$(get_remote_secret_value "$PG_RELEASE" postgres-password)"

  if run_remote "kubectl get secret $DB_USER_SECRET -n $NAMESPACE >/dev/null 2>&1"; then
    replenishment_user="$(get_remote_secret_value "$DB_USER_SECRET" RFQ_REPLENISHMENT_DB_USER)"
    replenishment_pass="$(get_remote_secret_value "$DB_USER_SECRET" RFQ_REPLENISHMENT_DB_PASSWORD)"
    triage_user="$(get_remote_secret_value "$DB_USER_SECRET" RFQ_ORDER_EXCEPTION_DB_USER)"
    triage_pass="$(get_remote_secret_value "$DB_USER_SECRET" RFQ_ORDER_EXCEPTION_DB_PASSWORD)"
  else
    replenishment_user="rfq_replenishment"
    triage_user="rfq_order_exception"
    replenishment_pass="$(openssl rand -hex 16)"
    triage_pass="$(openssl rand -hex 16)"

    run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $DB_USER_SECRET
  namespace: $NAMESPACE
type: Opaque
stringData:
  RFQ_REPLENISHMENT_DB_USER: '$replenishment_user'
  RFQ_REPLENISHMENT_DB_PASSWORD: '$replenishment_pass'
  RFQ_ORDER_EXCEPTION_DB_USER: '$triage_user'
  RFQ_ORDER_EXCEPTION_DB_PASSWORD: '$triage_pass'
YAML"
  fi

  bootstrap_sql="$(mktemp)"
  cat > "$bootstrap_sql" <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${replenishment_user}') THEN
    CREATE ROLE "${replenishment_user}" LOGIN PASSWORD '${replenishment_pass}';
  ELSE
    ALTER ROLE "${replenishment_user}" WITH LOGIN PASSWORD '${replenishment_pass}';
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${triage_user}') THEN
    CREATE ROLE "${triage_user}" LOGIN PASSWORD '${triage_pass}';
  ELSE
    ALTER ROLE "${triage_user}" WITH LOGIN PASSWORD '${triage_pass}';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE rfq_replenishment_planning OWNER "${replenishment_user}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rfq_replenishment_planning');
\gexec
GRANT ALL PRIVILEGES ON DATABASE rfq_replenishment_planning TO "${replenishment_user}";

SELECT 'CREATE DATABASE rfq_order_exception_triage OWNER "${triage_user}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rfq_order_exception_triage');
\gexec
GRANT ALL PRIVILEGES ON DATABASE rfq_order_exception_triage TO "${triage_user}";
SQL

  copy_to_remote "$bootstrap_sql" /tmp/operations-reuse-db-bootstrap.sql
  run_remote "kubectl -n $NAMESPACE cp /tmp/operations-reuse-db-bootstrap.sql ${PG_RELEASE}-0:/tmp/operations-reuse-db-bootstrap.sql"
  run_remote "kubectl -n $NAMESPACE exec ${PG_RELEASE}-0 -- bash -lc 'export PGPASSWORD=\"$pg_admin_password\"; psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f /tmp/operations-reuse-db-bootstrap.sql'"
  rm -f "$bootstrap_sql"

  run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: replenishment-planner-agent-db-bridge
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_URL: 'postgresql+psycopg2://${replenishment_user}:${replenishment_pass}@${PG_SERVICE}:${PG_PORT}/rfq_replenishment_planning'
  PGHOST: '${PG_SERVICE}'
  PGPORT: '${PG_PORT}'
  PGUSER: 'postgres'
  PGPASSWORD: '${pg_admin_password}'
YAML"

  run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: order-exception-triage-agent-db-bridge
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_URL: 'postgresql+psycopg2://${triage_user}:${triage_pass}@${PG_SERVICE}:${PG_PORT}/rfq_order_exception_triage'
  PGHOST: '${PG_SERVICE}'
  PGPORT: '${PG_PORT}'
  PGUSER: 'postgres'
  PGPASSWORD: '${pg_admin_password}'
YAML"
}

log "Applying dedicated RoleBindings for operations agents"
copy_to_remote "$RBAC_FILE" /tmp/operations-reuse-rbac.yaml
run_remote "kubectl apply -f /tmp/operations-reuse-rbac.yaml >/tmp/operations-reuse-rbac.apply.log && cat /tmp/operations-reuse-rbac.apply.log"

log "Ensuring dedicated RFQ databases and clean bridge secrets"
ensure_ops_databases

log "Deploying $REPLENISHMENT_RELEASE"
RELEASE_NAME="$REPLENISHMENT_RELEASE" VALUES_FILE="$REPLENISHMENT_VALUES" CONFIG_FILE="$REPLENISHMENT_CONFIG" "$SCRIPT_DIR/05_deploy_agent.sh"

log "Deploying $TRIAGE_RELEASE"
RELEASE_NAME="$TRIAGE_RELEASE" VALUES_FILE="$TRIAGE_VALUES" CONFIG_FILE="$TRIAGE_CONFIG" "$SCRIPT_DIR/05_deploy_agent.sh"

log "Restarting operations agent deployments to pick up refreshed secrets"
run_remote "kubectl -n $NAMESPACE rollout restart deploy/$REPLENISHMENT_RELEASE"
run_remote "kubectl -n $NAMESPACE rollout restart deploy/$TRIAGE_RELEASE"

log "Waiting for operations agents to roll out"
run_remote "kubectl -n $NAMESPACE rollout status deploy/$REPLENISHMENT_RELEASE --timeout=300s"
run_remote "kubectl -n $NAMESPACE rollout status deploy/$TRIAGE_RELEASE --timeout=300s"

log "Seeding prompt library"
"$SCRIPT_DIR/11_seed_prompt_library.sh"

project_name="$(jq -r '.name' "$PROJECT_FILE")"
copy_to_remote "$PROJECT_FILE" /tmp/operations-reuse-project.json

existing_project_id="$(
  run_remote "curl -s '$SAM_API_BASE_URL/projects?include_artifact_count=true' | jq -r --arg n '$project_name' '.projects[]? | select(.name==\$n) | .id' | head -n1"
)"

if [[ -n "$existing_project_id" && "$existing_project_id" != "null" ]]; then
  log "Updating existing project: $project_name ($existing_project_id)"
  http_code="$(run_remote "curl -s -o /tmp/operations-reuse-project-resp.json -w '%{http_code}' -X PUT '$SAM_API_BASE_URL/projects/$existing_project_id' -H 'Content-Type: application/json' --data @/tmp/operations-reuse-project.json")"
else
  name_file="$(mktemp)"
  desc_file="$(mktemp)"
  prompt_file="$(mktemp)"
  default_agent_file="$(mktemp)"

  jq -r '.name' "$PROJECT_FILE" > "$name_file"
  jq -r '.description // empty' "$PROJECT_FILE" > "$desc_file"
  jq -r '.systemPrompt // empty' "$PROJECT_FILE" > "$prompt_file"
  jq -r '.defaultAgentId // empty' "$PROJECT_FILE" > "$default_agent_file"

  copy_to_remote "$name_file" /tmp/operations-reuse-project.name
  copy_to_remote "$desc_file" /tmp/operations-reuse-project.description
  copy_to_remote "$prompt_file" /tmp/operations-reuse-project.system_prompt
  copy_to_remote "$default_agent_file" /tmp/operations-reuse-project.default_agent_id
  rm -f "$name_file" "$desc_file" "$prompt_file" "$default_agent_file"

  log "Creating project: $project_name"
  http_code="$(run_remote "name=\$(cat /tmp/operations-reuse-project.name); description=\$(cat /tmp/operations-reuse-project.description); system_prompt=\$(cat /tmp/operations-reuse-project.system_prompt); default_agent_id=\$(cat /tmp/operations-reuse-project.default_agent_id); curl -s -o /tmp/operations-reuse-project-resp.json -w '%{http_code}' -X POST '$SAM_API_BASE_URL/projects' --form-string \"name=\$name\" --form-string \"description=\$description\" --form-string \"system_prompt=\$system_prompt\" --form-string \"default_agent_id=\$default_agent_id\"")"
fi

if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
  log "Project apply failed (http $http_code)"
  run_remote "cat /tmp/operations-reuse-project-resp.json"
  exit 1
fi

project_id="$(run_remote "cat /tmp/operations-reuse-project-resp.json | jq -r '.id // empty'")"

if [[ -n "$project_id" ]]; then
  log "Applying canonical project update for default agent and prompt"
  http_code="$(run_remote "curl -s -o /tmp/operations-reuse-project-put-resp.json -w '%{http_code}' -X PUT '$SAM_API_BASE_URL/projects/$project_id' -H 'Content-Type: application/json' --data @/tmp/operations-reuse-project.json")"
  if [[ "$http_code" != "200" ]]; then
    log "Project update after create failed (http $http_code)"
    run_remote "cat /tmp/operations-reuse-project-put-resp.json"
    exit 1
  fi
  run_remote "cp /tmp/operations-reuse-project-put-resp.json /tmp/operations-reuse-project-resp.json"
fi

log "Project apply response"
run_remote "cat /tmp/operations-reuse-project-resp.json | jq '{id,name,defaultAgentId,createdAt,updatedAt}'"

log "Verifying discovered agent cards"
run_remote "curl -s '$SAM_API_BASE_URL/agentCards' | jq '[.[] | select((.agentName // .name)==\"OrderExceptionTriageAgent\" or (.agentName // .name)==\"ReplenishmentPlannerAgent\") | {name,agentName,id}]'"

log "Operations reuse deployment complete"
