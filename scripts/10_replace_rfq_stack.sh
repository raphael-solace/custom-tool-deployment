#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd jq
require_cmd curl
require_cmd awk
require_cmd sed
require_cmd openssl

load_local_env

NAMESPACE="${NAMESPACE:-default}"
PROJECT_ID="${PROJECT_ID:-4d6045fe-3207-4d4a-9fb9-6f853fd2392f}"
AGENT_SOURCE_DIR="${AGENT_SOURCE_DIR:-$ROOT_DIR/packages/custom-joule-agent}"
BASE_IMAGE="${BASE_IMAGE:-gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.97.2}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-docker.io/library/rfq-agent-suite}"
IMAGE_TAG="${IMAGE_TAG:-local-v1}"
IMAGE_PLATFORM="${IMAGE_PLATFORM:-linux/amd64}"
CUSTOM_IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
IMAGE_TAR="${IMAGE_TAR:-$BUILD_DIR/images/rfq-agent-suite-${IMAGE_TAG}.tar}"

PG_RELEASE="${PG_RELEASE:-rfq-postgresql}"
PG_SERVICE="${PG_SERVICE:-rfq-postgresql}"
PG_PORT="5432"

BACKUP_DIR="${BACKUP_DIR:-$BUILD_DIR/rfq-cutover-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$BACKUP_DIR" "$ROOT_DIR/deploy/rfq"

OLD_AGENT_IDS=(
  "019c8bb5-2823-7481-b57c-3a76aa53331f"
  "019c8bb6-e936-7152-899c-97e1788959ea"
  "019c8bb7-6eec-70c0-9c26-c689781369f8"
  "019c8bb8-1f51-7c42-8413-15e4095255f6"
)

OLD_RELEASES=(
  "sam-agent-019c8bb5-2823-7481-b57c-3a76aa53331f"
  "sam-agent-019c8bb6-e936-7152-899c-97e1788959ea"
  "sam-agent-019c8bb7-6eec-70c0-9c26-c689781369f8"
  "sam-agent-019c8bb8-1f51-7c42-8413-15e4095255f6"
)

NEW_RELEASES=(
  "acme-retail-pim"
  "sap-joule-agent"
  "shipping-agent"
  "quote-planning-agent"
)

rand_secret() {
  openssl rand -hex 12
}

require_non_empty() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    log "Required value is empty: $name"
    exit 1
  fi
}

get_remote_secret_value() {
  local secret_name="$1"
  local key="$2"
  run_remote "kubectl get secret -n $NAMESPACE $secret_name -o json | jq -r --arg k '$key' '.data[\$k] // empty' | base64 -d"
}

extract_quoted_yaml_value() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    $1==k":" {
      line=$0
      sub(/^[^:]*:[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      print line
      exit
    }
  ' "$file"
}

extract_placeholder_default() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    $1==k":" {
      line=$0
      if (match(line, /\$\{[^,]+,[[:space:]]*[^}]+\}/)) {
        val=substr(line, RSTART, RLENGTH)
        sub(/^\$\{[^,]+,[[:space:]]*/, "", val)
        sub(/\}$/, "", val)
        gsub(/^"|"$/, "", val)
        print val
      }
      exit
    }
  ' "$file"
}

log "Step 1/8: Freeze + backup current state into $BACKUP_DIR"
run_remote "curl -s 'http://192.168.32.100/api/v1/platform/agents?pageNumber=1&pageSize=200'" > "$BACKUP_DIR/platform-agents-before.json"
for id in "${OLD_AGENT_IDS[@]}"; do
  run_remote "curl -s 'http://192.168.32.100/api/v1/platform/agents/$id/configuration'" > "$BACKUP_DIR/platform-agent-config-$id.json"
done
for release in "${OLD_RELEASES[@]}"; do
  run_remote "helm get values -n $NAMESPACE $release -a" > "$BACKUP_DIR/helm-values-$release.yaml" || true
  run_remote "helm get manifest -n $NAMESPACE $release" > "$BACKUP_DIR/helm-manifest-$release.yaml" || true
done
run_remote "curl -s 'http://192.168.32.100/api/v1/projects?include_artifact_count=true'" > "$BACKUP_DIR/projects-before.json"
run_remote "curl -s 'http://192.168.32.100/api/v1/projects/$PROJECT_ID'" > "$BACKUP_DIR/project-$PROJECT_ID-before.json"

log "Step 2/8: Capture shared runtime values (broker/llm/s3/namespaceId)"
ENV_SECRET="agent-mesh-environment"
SOLACE_BROKER_URL="$(get_remote_secret_value "$ENV_SECRET" SOLACE_BROKER_URL)"
SOLACE_BROKER_USERNAME="$(get_remote_secret_value "$ENV_SECRET" SOLACE_BROKER_USERNAME)"
SOLACE_BROKER_PASSWORD="$(get_remote_secret_value "$ENV_SECRET" SOLACE_BROKER_PASSWORD)"
SOLACE_BROKER_VPN="$(get_remote_secret_value "$ENV_SECRET" SOLACE_BROKER_VPN)"
LLM_MODEL="${LLM_MODEL_OVERRIDE:-$(get_remote_secret_value "$ENV_SECRET" LLM_SERVICE_GENERAL_MODEL_NAME)}"
LLM_PLANNING_MODEL="${LLM_PLANNING_MODEL_OVERRIDE:-$(get_remote_secret_value "$ENV_SECRET" LLM_SERVICE_PLANNING_MODEL_NAME)}"
LLM_ENDPOINT="${LLM_ENDPOINT_OVERRIDE:-$(get_remote_secret_value "$ENV_SECRET" LLM_SERVICE_ENDPOINT)}"
LLM_API_KEY="${LLM_API_KEY_OVERRIDE:-$(get_remote_secret_value "$ENV_SECRET" LLM_SERVICE_API_KEY)}"
S3_ENDPOINT_URL="$(get_remote_secret_value agent-mesh-persistence S3_ENDPOINT_URL)"
S3_BUCKET_NAME="$(get_remote_secret_value agent-mesh-persistence S3_BUCKET_NAME)"
S3_ACCESS_KEY_ID="$(get_remote_secret_value agent-mesh-persistence AWS_ACCESS_KEY_ID)"
S3_SECRET_ACCESS_KEY="$(get_remote_secret_value agent-mesh-persistence AWS_SECRET_ACCESS_KEY)"
S3_REGION="$(get_remote_secret_value agent-mesh-persistence AWS_REGION)"
NAMESPACE_ID="$(run_remote "kubectl get secret -n $NAMESPACE agent-mesh-postgresql -o json | jq -r '.metadata.labels[\"app.kubernetes.io/namespace-id\"] // empty'")"

require_non_empty SOLACE_BROKER_URL "$SOLACE_BROKER_URL"
require_non_empty SOLACE_BROKER_USERNAME "$SOLACE_BROKER_USERNAME"
require_non_empty SOLACE_BROKER_PASSWORD "$SOLACE_BROKER_PASSWORD"
require_non_empty SOLACE_BROKER_VPN "$SOLACE_BROKER_VPN"
require_non_empty LLM_MODEL "$LLM_MODEL"
require_non_empty LLM_PLANNING_MODEL "$LLM_PLANNING_MODEL"
require_non_empty LLM_ENDPOINT "$LLM_ENDPOINT"
require_non_empty LLM_API_KEY "$LLM_API_KEY"
require_non_empty S3_ENDPOINT_URL "$S3_ENDPOINT_URL"
require_non_empty S3_BUCKET_NAME "$S3_BUCKET_NAME"
require_non_empty S3_ACCESS_KEY_ID "$S3_ACCESS_KEY_ID"
require_non_empty S3_SECRET_ACCESS_KEY "$S3_SECRET_ACCESS_KEY"
require_non_empty S3_REGION "$S3_REGION"
require_non_empty NAMESPACE_ID "$NAMESPACE_ID"

log "Step 3/8: Hard-remove old demo agents and legacy release"
for id in "${OLD_AGENT_IDS[@]}"; do
  code="$(run_remote "curl -s -o /tmp/del-agent.out -w '%{http_code}' -X DELETE 'http://192.168.32.100/api/v1/platform/agents/$id' || true")"
  if [[ "$code" != "204" && "$code" != "404" ]]; then
    run_remote "cat /tmp/del-agent.out"
    log "Failed deleting agent id=$id (http $code)"
    exit 1
  fi
done

for release in "${OLD_RELEASES[@]}"; do
  run_remote "helm -n $NAMESPACE status $release >/dev/null 2>&1 && helm -n $NAMESPACE uninstall $release || true"
done

run_remote "curl -s 'http://192.168.32.100/api/v1/platform/agents?pageNumber=1&pageSize=200'" > "$BACKUP_DIR/platform-agents-after-removal.json"
run_remote "helm list -n $NAMESPACE" > "$BACKUP_DIR/helm-list-after-removal.txt"
run_remote "kubectl -n $NAMESPACE get pods -o wide" > "$BACKUP_DIR/pods-after-removal.txt"

if [[ "${SKIP_IMAGE_BUILD_IMPORT:-false}" == "true" ]]; then
  log "Step 4/8: Skipping image build/import (SKIP_IMAGE_BUILD_IMPORT=true)"
else
  log "Step 4/8: Build and import shared RFQ custom image"
  AGENT_SOURCE_DIR="$AGENT_SOURCE_DIR" \
  BASE_IMAGE="$BASE_IMAGE" \
  CUSTOM_IMAGE="$CUSTOM_IMAGE" \
  IMAGE_TAR="$IMAGE_TAR" \
  IMAGE_PLATFORM="$IMAGE_PLATFORM" \
  IMAGE_DISTRIBUTION_MODE="k3s" \
  PUSH_IMAGE="false" \
  "$SCRIPT_DIR/02_build_image.sh"

  IMAGE_TAR="$IMAGE_TAR" \
  IMAGE_MATCH_PATTERN="rfq-agent-suite|$IMAGE_REPOSITORY" \
  "$SCRIPT_DIR/03_import_image_to_k3s.sh"
fi

log "Step 5/8: Deploy dedicated PostgreSQL and seed PIM DB"
PG_VALUES_LOCAL="$BACKUP_DIR/rfq-postgresql-values.yaml"
if run_remote "kubectl -n $NAMESPACE get secret $PG_RELEASE >/dev/null 2>&1"; then
  PG_ADMIN_PASSWORD="$(get_remote_secret_value "$PG_RELEASE" postgres-password)"
else
  PG_ADMIN_PASSWORD="$(rand_secret)"
fi

cat > "$PG_VALUES_LOCAL" <<YAML
architecture: standalone
auth:
  enablePostgresUser: true
  postgresPassword: "$PG_ADMIN_PASSWORD"
primary:
  persistence:
    enabled: true
    size: 8Gi
YAML

copy_to_remote "$PG_VALUES_LOCAL" /tmp/rfq-postgresql-values.yaml
run_remote "helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true"
run_remote "helm repo update bitnami >/dev/null"
run_remote "helm upgrade --install $PG_RELEASE bitnami/postgresql -n $NAMESPACE -f /tmp/rfq-postgresql-values.yaml --wait"
run_remote "kubectl -n $NAMESPACE rollout status statefulset/$PG_RELEASE --timeout=300s"

if run_remote "kubectl -n $NAMESPACE get secret rfq-db-users >/dev/null 2>&1"; then
  RFQ_QUOTE_USER="$(get_remote_secret_value rfq-db-users RFQ_QUOTE_PLANNING_DB_USER)"
  RFQ_QUOTE_PASS="$(get_remote_secret_value rfq-db-users RFQ_QUOTE_PLANNING_DB_PASSWORD)"
  RFQ_SAP_USER="$(get_remote_secret_value rfq-db-users RFQ_SAP_JOULE_DB_USER)"
  RFQ_SAP_PASS="$(get_remote_secret_value rfq-db-users RFQ_SAP_JOULE_DB_PASSWORD)"
  RFQ_SHIP_USER="$(get_remote_secret_value rfq-db-users RFQ_SHIPPING_DB_USER)"
  RFQ_SHIP_PASS="$(get_remote_secret_value rfq-db-users RFQ_SHIPPING_DB_PASSWORD)"
  RFQ_PIM_USER="$(get_remote_secret_value rfq-db-users RFQ_ACME_PIM_DB_USER)"
  RFQ_PIM_PASS="$(get_remote_secret_value rfq-db-users RFQ_ACME_PIM_DB_PASSWORD)"
else
  RFQ_QUOTE_USER="rfq_quote_planning"
  RFQ_SAP_USER="rfq_sap_joule"
  RFQ_SHIP_USER="rfq_shipping"
  RFQ_PIM_USER="rfq_acme_pim"
  RFQ_QUOTE_PASS="$(rand_secret)"
  RFQ_SAP_PASS="$(rand_secret)"
  RFQ_SHIP_PASS="$(rand_secret)"
  RFQ_PIM_PASS="$(rand_secret)"

  run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: rfq-db-users
  namespace: $NAMESPACE
type: Opaque
stringData:
  RFQ_QUOTE_PLANNING_DB_USER: '$RFQ_QUOTE_USER'
  RFQ_QUOTE_PLANNING_DB_PASSWORD: '$RFQ_QUOTE_PASS'
  RFQ_SAP_JOULE_DB_USER: '$RFQ_SAP_USER'
  RFQ_SAP_JOULE_DB_PASSWORD: '$RFQ_SAP_PASS'
  RFQ_SHIPPING_DB_USER: '$RFQ_SHIP_USER'
  RFQ_SHIPPING_DB_PASSWORD: '$RFQ_SHIP_PASS'
  RFQ_ACME_PIM_DB_USER: '$RFQ_PIM_USER'
  RFQ_ACME_PIM_DB_PASSWORD: '$RFQ_PIM_PASS'
YAML"
fi

require_non_empty RFQ_QUOTE_USER "$RFQ_QUOTE_USER"
require_non_empty RFQ_QUOTE_PASS "$RFQ_QUOTE_PASS"
require_non_empty RFQ_SAP_USER "$RFQ_SAP_USER"
require_non_empty RFQ_SAP_PASS "$RFQ_SAP_PASS"
require_non_empty RFQ_SHIP_USER "$RFQ_SHIP_USER"
require_non_empty RFQ_SHIP_PASS "$RFQ_SHIP_PASS"
require_non_empty RFQ_PIM_USER "$RFQ_PIM_USER"
require_non_empty RFQ_PIM_PASS "$RFQ_PIM_PASS"

PG_BOOTSTRAP_SQL="$BACKUP_DIR/rfq-db-bootstrap.sql"
cat > "$PG_BOOTSTRAP_SQL" <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${RFQ_QUOTE_USER}') THEN
    CREATE ROLE "${RFQ_QUOTE_USER}" LOGIN PASSWORD '${RFQ_QUOTE_PASS}';
  ELSE
    ALTER ROLE "${RFQ_QUOTE_USER}" WITH LOGIN PASSWORD '${RFQ_QUOTE_PASS}';
  END IF;
END
\$\$;
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${RFQ_SAP_USER}') THEN
    CREATE ROLE "${RFQ_SAP_USER}" LOGIN PASSWORD '${RFQ_SAP_PASS}';
  ELSE
    ALTER ROLE "${RFQ_SAP_USER}" WITH LOGIN PASSWORD '${RFQ_SAP_PASS}';
  END IF;
END
\$\$;
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${RFQ_SHIP_USER}') THEN
    CREATE ROLE "${RFQ_SHIP_USER}" LOGIN PASSWORD '${RFQ_SHIP_PASS}';
  ELSE
    ALTER ROLE "${RFQ_SHIP_USER}" WITH LOGIN PASSWORD '${RFQ_SHIP_PASS}';
  END IF;
END
\$\$;
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${RFQ_PIM_USER}') THEN
    CREATE ROLE "${RFQ_PIM_USER}" LOGIN PASSWORD '${RFQ_PIM_PASS}';
  ELSE
    ALTER ROLE "${RFQ_PIM_USER}" WITH LOGIN PASSWORD '${RFQ_PIM_PASS}';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE rfq_quote_planning OWNER "${RFQ_QUOTE_USER}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rfq_quote_planning');
\gexec
GRANT ALL PRIVILEGES ON DATABASE rfq_quote_planning TO "${RFQ_QUOTE_USER}";

SELECT 'CREATE DATABASE rfq_sap_joule OWNER "${RFQ_SAP_USER}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rfq_sap_joule');
\gexec
GRANT ALL PRIVILEGES ON DATABASE rfq_sap_joule TO "${RFQ_SAP_USER}";

SELECT 'CREATE DATABASE rfq_shipping OWNER "${RFQ_SHIP_USER}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rfq_shipping');
\gexec
GRANT ALL PRIVILEGES ON DATABASE rfq_shipping TO "${RFQ_SHIP_USER}";

SELECT 'CREATE DATABASE rfq_acme_pim OWNER "${RFQ_PIM_USER}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rfq_acme_pim');
\gexec
GRANT ALL PRIVILEGES ON DATABASE rfq_acme_pim TO "${RFQ_PIM_USER}";
SQL

copy_to_remote "$PG_BOOTSTRAP_SQL" /tmp/rfq-db-bootstrap.sql
run_remote "kubectl -n $NAMESPACE cp /tmp/rfq-db-bootstrap.sql ${PG_RELEASE}-0:/tmp/rfq-db-bootstrap.sql"
run_remote "kubectl -n $NAMESPACE exec ${PG_RELEASE}-0 -- bash -lc 'export PGPASSWORD=\"$PG_ADMIN_PASSWORD\"; psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f /tmp/rfq-db-bootstrap.sql'"

copy_to_remote "$ROOT_DIR/packages/custom-joule-agent/scripts/acme_retail_pim.sql" /tmp/acme_retail_pim.sql
run_remote "kubectl -n $NAMESPACE cp /tmp/acme_retail_pim.sql ${PG_RELEASE}-0:/tmp/acme_retail_pim.sql"
run_remote "kubectl -n $NAMESPACE exec ${PG_RELEASE}-0 -- bash -lc '
set -euo pipefail
export PGPASSWORD=\"$PG_ADMIN_PASSWORD\"
cat /tmp/acme_retail_pim.sql | sed \"/^\\\\restrict /d\" | sed \"/^\\\\unrestrict /d\" | sed \"/OWNER TO /d\" > /tmp/acme_retail_pim.sanitized.sql
PGPASSWORD=\"$RFQ_PIM_PASS\" psql -h 127.0.0.1 -U \"$RFQ_PIM_USER\" -d rfq_acme_pim -v ON_ERROR_STOP=1 -f /tmp/acme_retail_pim.sanitized.sql >/tmp/acme_pim_load.log
psql -U postgres -d rfq_acme_pim -At -c \"SELECT count(*) FROM products;\"
'" > "$BACKUP_DIR/pim-products-count.txt"

log "Step 6/8: Create credential/config secrets"
SAP_CONFIG_FILE="$ROOT_DIR/packages/custom-joule-agent/configs/agents/sap-joule-agent.yaml"
SHIP_CONFIG_FILE="$ROOT_DIR/packages/custom-joule-agent/configs/agents/shipping-agent.yaml"

SAP_TOKEN_URL="${SAP_TOKEN_URL:-$(extract_quoted_yaml_value "$SAP_CONFIG_FILE" token_url)}"
SAP_BASE_URL="${SAP_BASE_URL:-$(extract_quoted_yaml_value "$SAP_CONFIG_FILE" base_url)}"
SAP_AGENT_ID="${SAP_AGENT_ID:-$(extract_quoted_yaml_value "$SAP_CONFIG_FILE" agent_id)}"
SAP_CLIENT_ID="${SAP_CLIENT_ID:-$(extract_placeholder_default "$SAP_CONFIG_FILE" client_id)}"
SAP_CLIENT_SECRET="${SAP_CLIENT_SECRET:-$(extract_placeholder_default "$SAP_CONFIG_FILE" client_secret)}"
SAP_REQUEST_TIMEOUT="${SAP_REQUEST_TIMEOUT:-30}"
SAP_SSL_VERIFY="${SAP_SSL_VERIFY:-false}"

SHIPENGINE_API_KEY="${SHIPENGINE_API_KEY:-$(extract_quoted_yaml_value "$SHIP_CONFIG_FILE" api_key)}"
SHIPENGINE_CARRIER_ID_1="${SHIPENGINE_CARRIER_ID_1:-se-351051}"
SHIPENGINE_CARRIER_ID_2="${SHIPENGINE_CARRIER_ID_2:-se-351050}"
SHIPENGINE_CARRIER_ID_3="${SHIPENGINE_CARRIER_ID_3:-se-351052}"
SHIPENGINE_CARRIER_ID_4="${SHIPENGINE_CARRIER_ID_4:-se-360528}"
SHIP_FROM_NAME="${SHIP_FROM_NAME:-Acme Retail Warehouse}"
SHIP_FROM_PHONE="${SHIP_FROM_PHONE:-222-333-4444}"
SHIP_FROM_COMPANY_NAME="${SHIP_FROM_COMPANY_NAME:-Acme Retail}"
SHIP_FROM_RESIDENTIAL_INDICATOR="${SHIP_FROM_RESIDENTIAL_INDICATOR:-no}"

require_non_empty SAP_TOKEN_URL "$SAP_TOKEN_URL"
require_non_empty SAP_BASE_URL "$SAP_BASE_URL"
require_non_empty SAP_AGENT_ID "$SAP_AGENT_ID"
require_non_empty SAP_CLIENT_ID "$SAP_CLIENT_ID"
require_non_empty SAP_CLIENT_SECRET "$SAP_CLIENT_SECRET"
require_non_empty SHIPENGINE_API_KEY "$SHIPENGINE_API_KEY"

run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: sap-joule-credentials
  namespace: $NAMESPACE
type: Opaque
stringData:
  SAP_TOKEN_URL: '$SAP_TOKEN_URL'
  SAP_BASE_URL: '$SAP_BASE_URL'
  SAP_AGENT_ID: '$SAP_AGENT_ID'
  SAP_CLIENT_ID: '$SAP_CLIENT_ID'
  SAP_CLIENT_SECRET: '$SAP_CLIENT_SECRET'
  SAP_REQUEST_TIMEOUT: '$SAP_REQUEST_TIMEOUT'
  SAP_SSL_VERIFY: '$SAP_SSL_VERIFY'
YAML"

run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: shipping-agent-credentials
  namespace: $NAMESPACE
type: Opaque
stringData:
  SHIPENGINE_API_KEY: '$SHIPENGINE_API_KEY'
  SHIPENGINE_CARRIER_ID_1: '$SHIPENGINE_CARRIER_ID_1'
  SHIPENGINE_CARRIER_ID_2: '$SHIPENGINE_CARRIER_ID_2'
  SHIPENGINE_CARRIER_ID_3: '$SHIPENGINE_CARRIER_ID_3'
  SHIPENGINE_CARRIER_ID_4: '$SHIPENGINE_CARRIER_ID_4'
  SHIP_FROM_NAME: '$SHIP_FROM_NAME'
  SHIP_FROM_PHONE: '$SHIP_FROM_PHONE'
  SHIP_FROM_COMPANY_NAME: '$SHIP_FROM_COMPANY_NAME'
  SHIP_FROM_RESIDENTIAL_INDICATOR: '$SHIP_FROM_RESIDENTIAL_INDICATOR'
YAML"

run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: acme-retail-pim-db-config
  namespace: $NAMESPACE
type: Opaque
stringData:
  ACME_RETAIL_PIM_DB_TYPE: 'postgresql'
  ACME_RETAIL_PIM_DB_HOST: '$PG_SERVICE'
  ACME_RETAIL_PIM_DB_PORT: '$PG_PORT'
  ACME_RETAIL_PIM_DB_USER: '$RFQ_PIM_USER'
  ACME_RETAIL_PIM_DB_PASSWORD: '$RFQ_PIM_PASS'
  ACME_RETAIL_PIM_DB_NAME: 'rfq_acme_pim'
YAML"

create_db_bridge_secret() {
  local name="$1"
  local app_user="$2"
  local app_pass="$3"
  local app_db="$4"
  local database_url="postgresql+psycopg2://${app_user}:${app_pass}@${PG_SERVICE}:${PG_PORT}/${app_db}"

  run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $name
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_URL: '$database_url'
  PGHOST: '$PG_SERVICE'
  PGPORT: '$PG_PORT'
  PGUSER: 'postgres'
  PGPASSWORD: '$PG_ADMIN_PASSWORD'
YAML"
}

create_db_bridge_secret "acme-retail-pim-db-bridge" "$RFQ_PIM_USER" "$RFQ_PIM_PASS" "rfq_acme_pim"
create_db_bridge_secret "sap-joule-agent-db-bridge" "$RFQ_SAP_USER" "$RFQ_SAP_PASS" "rfq_sap_joule"
create_db_bridge_secret "shipping-agent-db-bridge" "$RFQ_SHIP_USER" "$RFQ_SHIP_PASS" "rfq_shipping"
create_db_bridge_secret "quote-planning-agent-db-bridge" "$RFQ_QUOTE_USER" "$RFQ_QUOTE_PASS" "rfq_quote_planning"

log "Step 7/8: Generate values and deploy four standalone agents"

generate_values_file() {
  mkdir -p "$BUILD_DIR/rfq-values"
  local release="$1"
  local db_secret="$2"
  local values_file="$BUILD_DIR/rfq-values/${release}-values.generated.yaml"

  cat > "$values_file" <<YAML
deploymentMode: standalone
id: ${release}

global:
  persistence:
    namespaceId: '${NAMESPACE_ID}'

serviceAccount:
  name: solace-agent-mesh-sa

image:
  repository: '${IMAGE_REPOSITORY}'
  tag: '${IMAGE_TAG}'
  pullPolicy: IfNotPresent

solaceBroker:
  url: '${SOLACE_BROKER_URL}'
  username: '${SOLACE_BROKER_USERNAME}'
  password: '${SOLACE_BROKER_PASSWORD}'
  vpn: '${SOLACE_BROKER_VPN}'
  useTemporaryQueues: true

llmService:
  generalModelName: '${LLM_MODEL}'
  endpoint: '${LLM_ENDPOINT}'
  apiKey: '${LLM_API_KEY}'

environmentVariables:
  LLM_SERVICE_PLANNING_MODEL_NAME: '${LLM_PLANNING_MODEL:-$LLM_MODEL}'

persistence:
  existingSecrets:
    database: '${db_secret}'
    s3: ''

  s3:
    endpointUrl: '${S3_ENDPOINT_URL}'
    bucketName: '${S3_BUCKET_NAME}'
    accessKey: '${S3_ACCESS_KEY_ID}'
    secretKey: '${S3_SECRET_ACCESS_KEY}'
    region: '${S3_REGION}'

resources:
  sam:
    requests:
      cpu: 500m
      memory: 768Mi
    limits:
      cpu: 1500m
      memory: 1536Mi

rollout:
  strategy: Recreate
YAML

  chmod 600 "$values_file"
}

generate_values_file "acme-retail-pim" "acme-retail-pim-db-bridge"
generate_values_file "sap-joule-agent" "sap-joule-agent-db-bridge"
generate_values_file "shipping-agent" "shipping-agent-db-bridge"
generate_values_file "quote-planning-agent" "quote-planning-agent-db-bridge"

NAMESPACE="$NAMESPACE" RELEASE_NAME="acme-retail-pim" VALUES_FILE="$BUILD_DIR/rfq-values/acme-retail-pim-values.generated.yaml" CONFIG_FILE="$ROOT_DIR/deploy/rfq/acme-retail-pim-config.yaml" "$SCRIPT_DIR/05_deploy_agent.sh"
NAMESPACE="$NAMESPACE" RELEASE_NAME="sap-joule-agent" VALUES_FILE="$BUILD_DIR/rfq-values/sap-joule-agent-values.generated.yaml" CONFIG_FILE="$ROOT_DIR/deploy/rfq/sap-joule-agent-config.yaml" "$SCRIPT_DIR/05_deploy_agent.sh"
NAMESPACE="$NAMESPACE" RELEASE_NAME="shipping-agent" VALUES_FILE="$BUILD_DIR/rfq-values/shipping-agent-values.generated.yaml" CONFIG_FILE="$ROOT_DIR/deploy/rfq/shipping-agent-config.yaml" "$SCRIPT_DIR/05_deploy_agent.sh"
NAMESPACE="$NAMESPACE" RELEASE_NAME="quote-planning-agent" VALUES_FILE="$BUILD_DIR/rfq-values/quote-planning-agent-values.generated.yaml" CONFIG_FILE="$ROOT_DIR/deploy/rfq/quote-planning-agent-config.yaml" "$SCRIPT_DIR/05_deploy_agent.sh"

run_remote "kubectl -n $NAMESPACE set env deployment/sap-joule-agent -c sam --from=secret/sap-joule-credentials"
run_remote "kubectl -n $NAMESPACE set env deployment/shipping-agent -c sam --from=secret/shipping-agent-credentials"
run_remote "kubectl -n $NAMESPACE set env deployment/acme-retail-pim -c sam --from=secret/acme-retail-pim-db-config"

for release in "${NEW_RELEASES[@]}"; do
  run_remote "kubectl -n $NAMESPACE rollout status deployment/$release --timeout=300s"
done

log "Step 8/8: Verify and update RFQ project"
run_remote "curl -s 'http://192.168.32.100/api/v1/platform/agents?pageNumber=1&pageSize=200'" > "$BACKUP_DIR/platform-agents-after-new-deploy.json"
run_remote "kubectl -n $NAMESPACE get deploy,pod -o wide" > "$BACKUP_DIR/workloads-after-new-deploy.txt"

run_remote "pod=\$(kubectl -n $NAMESPACE get pod -l app.kubernetes.io/instance=sap-joule-agent -o jsonpath='{.items[0].metadata.name}'); kubectl -n $NAMESPACE exec -i \$pod -c sam -- python - <<'PY'
import os, asyncio, importlib
m=importlib.import_module('src.sap-joule-agent.tools')
cfg={
    'token_url': os.environ['SAP_TOKEN_URL'],
    'client_id': os.environ['SAP_CLIENT_ID'],
    'client_secret': os.environ['SAP_CLIENT_SECRET'],
    'request_timeout': int(os.environ.get('SAP_REQUEST_TIMEOUT','30')),
    'ssl_verify': os.environ.get('SAP_SSL_VERIFY','false').lower() == 'true',
}
out=asyncio.run(m.get_authentication_token_for_BAF(tool_config=cfg))
print({'status': out.get('status'), 'message': out.get('message')})
PY" > "$BACKUP_DIR/sap-tool-smoke.txt"

run_remote "pod=\$(kubectl -n $NAMESPACE get pod -l app.kubernetes.io/instance=shipping-agent -o jsonpath='{.items[0].metadata.name}'); kubectl -n $NAMESPACE exec -i \$pod -c sam -- python - <<'PY'
import asyncio, importlib
m=importlib.import_module('src.shipping-agent.tools')
out=asyncio.run(m.get_shipping_rates(
    ship_from_address_line1='Warehouse 1',
    ship_from_city_locality='Berlin',
    ship_from_state_province='BE',
    ship_from_postal_code='10115',
    ship_from_country_code='DE',
    ship_to_name='Test Customer',
    ship_to_phone='1111111111',
    ship_to_address_line1='1 Main St',
    ship_to_city_locality='Munich',
    ship_to_state_province='BY',
    ship_to_postal_code='80331',
    ship_to_country_code='DE',
    package_code='package',
    weight_value=10,
    weight_unit='kilogram',
    ship_to_company_name='ACME GmbH'
))
print({'status': out.get('status'), 'rates_count': len(out.get('rates', [])) if isinstance(out.get('rates'), list) else 0})
PY" > "$BACKUP_DIR/shipping-tool-smoke.txt"

run_remote "kubectl -n $NAMESPACE exec ${PG_RELEASE}-0 -- bash -lc 'export PGPASSWORD=\"$PG_ADMIN_PASSWORD\"; psql -U postgres -d rfq_acme_pim -At -c \"SELECT count(*) FROM products;\"'" > "$BACKUP_DIR/pim-products-count-after-deploy.txt"
run_remote "pod=\$(kubectl -n $NAMESPACE get pod -l app.kubernetes.io/instance=quote-planning-agent -o jsonpath='{.items[0].metadata.name}'); kubectl -n $NAMESPACE exec \$pod -c sam -- sh -lc \"grep -n 'allow_list' -n /app/config/agent.yaml && grep -n 'SapJouleAgent\\|ShippingAgent\\|AcmeRetailPim' /app/config/agent.yaml\"" > "$BACKUP_DIR/quote-agent-allow-list-check.txt"

PROD_PROMPT_FILE="$BACKUP_DIR/rfq-project-prod-prompt.txt"
cat > "$PROD_PROMPT_FILE" <<'PROMPT'
You are coordinating a production RFQ workflow across QuotePlanningAgent, SapJouleAgent, ShippingAgent, and AcmeRetailPim.

Operating rules:
- Use real tool outputs from these agents; do not invent backend values.
- If any required RFQ input is missing, ask for it explicitly.
- Keep a clear execution trace of which agent provided each part of the final quote.
- Final quote must include product details, sourcing decision, shipping options, and cost breakdown.
PROMPT

PROJECT_UPDATE_JSON="$BACKUP_DIR/project-update.json"
python3 - <<PY
import json
from pathlib import Path
project=json.loads(Path("$BACKUP_DIR/project-$PROJECT_ID-before.json").read_text())
current=project.get("project",{})
update={
  "name": current.get("name","RFQ Automation"),
  "description": current.get("description", "RFQ automation with real SAP, shipping and PIM data"),
  "systemPrompt": Path("$PROD_PROMPT_FILE").read_text(),
  "defaultAgentId": "QuotePlanningAgent"
}
Path("$PROJECT_UPDATE_JSON").write_text(json.dumps(update))
PY

copy_to_remote "$PROJECT_UPDATE_JSON" /tmp/rfq-project-update.json
run_remote "curl -s -X PUT 'http://192.168.32.100/api/v1/projects/$PROJECT_ID' -H 'Content-Type: application/json' --data @/tmp/rfq-project-update.json > /tmp/project-update-response.json"
copy_from_remote /tmp/project-update-response.json "$BACKUP_DIR/project-update-response.json"

log "Cutover completed successfully"
log "Backups and verification artifacts: $BACKUP_DIR"
