#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

NAMESPACE="${NAMESPACE:-default}"
AGENT_ID="${AGENT_ID:-custom-echo-agent}"
DB_SECRET_NAME="${DB_SECRET_NAME:-custom-echo-agent-db-bridge}"
VALUES_OUT="${VALUES_OUT:-$ROOT_DIR/deploy/custom-echo-agent-values.generated.yaml}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-docker.io/library/custom-echo-agent}"
IMAGE_TAG="${IMAGE_TAG:-local-v1}"

get_secret_value() {
  local secret_name="$1"
  local key="$2"
  run_remote "kubectl get secret -n $NAMESPACE $secret_name -o json | jq -r --arg k '$key' '.data[\$k] // empty' | base64 -d"
}

get_secret_label() {
  local secret_name="$1"
  local key="$2"
  run_remote "kubectl get secret -n $NAMESPACE $secret_name -o json | jq -r --arg k '$key' '.metadata.labels[\$k] // empty'"
}

require_non_empty() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    log "Required value is empty: $name"
    exit 1
  fi
}

log "Collecting existing SAM runtime values from cluster"
SOURCE_RELEASE="$(run_remote "helm list -n $NAMESPACE -q | rg '^sam-agent-' | head -n 1")"
if [[ -z "$SOURCE_RELEASE" ]]; then
  log "No existing sam-agent-* release found in namespace $NAMESPACE"
  exit 1
fi

ENV_SECRET="${SOURCE_RELEASE}-env-vars"
NAMESPACE_ID="$(get_secret_label agent-mesh-postgresql app.kubernetes.io/namespace-id)"

PGHOST="$(get_secret_value agent-mesh-postgresql PGHOST)"
PGPORT="$(get_secret_value agent-mesh-postgresql PGPORT)"
PGUSER="$(get_secret_value agent-mesh-postgresql PGUSER)"
PGPASSWORD="$(get_secret_value agent-mesh-postgresql PGPASSWORD)"

SOLACE_BROKER_URL="$(get_secret_value "$ENV_SECRET" SOLACE_BROKER_URL)"
SOLACE_BROKER_USERNAME="$(get_secret_value "$ENV_SECRET" SOLACE_BROKER_USERNAME)"
SOLACE_BROKER_PASSWORD="$(get_secret_value "$ENV_SECRET" SOLACE_BROKER_PASSWORD)"
SOLACE_BROKER_VPN="$(get_secret_value "$ENV_SECRET" SOLACE_BROKER_VPN)"
LLM_MODEL="$(get_secret_value "$ENV_SECRET" LLM_SERVICE_GENERAL_MODEL_NAME)"
LLM_ENDPOINT="$(get_secret_value "$ENV_SECRET" LLM_SERVICE_ENDPOINT)"
LLM_API_KEY="$(get_secret_value "$ENV_SECRET" LLM_SERVICE_API_KEY)"

S3_ENDPOINT_URL="$(get_secret_value agent-mesh-persistence S3_ENDPOINT_URL)"
S3_BUCKET_NAME="$(get_secret_value agent-mesh-persistence S3_BUCKET_NAME)"
S3_ACCESS_KEY_ID="$(get_secret_value agent-mesh-persistence AWS_ACCESS_KEY_ID)"
S3_SECRET_ACCESS_KEY="$(get_secret_value agent-mesh-persistence AWS_SECRET_ACCESS_KEY)"
S3_REGION="$(get_secret_value agent-mesh-persistence AWS_REGION)"

require_non_empty "NAMESPACE_ID" "$NAMESPACE_ID"
require_non_empty "PGHOST" "$PGHOST"
require_non_empty "PGPORT" "$PGPORT"
require_non_empty "PGUSER" "$PGUSER"
require_non_empty "PGPASSWORD" "$PGPASSWORD"
require_non_empty "SOLACE_BROKER_URL" "$SOLACE_BROKER_URL"
require_non_empty "SOLACE_BROKER_USERNAME" "$SOLACE_BROKER_USERNAME"
require_non_empty "SOLACE_BROKER_PASSWORD" "$SOLACE_BROKER_PASSWORD"
require_non_empty "SOLACE_BROKER_VPN" "$SOLACE_BROKER_VPN"
require_non_empty "LLM_MODEL" "$LLM_MODEL"
require_non_empty "LLM_ENDPOINT" "$LLM_ENDPOINT"
require_non_empty "LLM_API_KEY" "$LLM_API_KEY"
require_non_empty "S3_ENDPOINT_URL" "$S3_ENDPOINT_URL"
require_non_empty "S3_BUCKET_NAME" "$S3_BUCKET_NAME"
require_non_empty "S3_ACCESS_KEY_ID" "$S3_ACCESS_KEY_ID"
require_non_empty "S3_SECRET_ACCESS_KEY" "$S3_SECRET_ACCESS_KEY"
require_non_empty "S3_REGION" "$S3_REGION"

AGENT_DB_USER="${NAMESPACE_ID}_${AGENT_ID}_agent"
AGENT_DB_PASSWORD="$AGENT_DB_USER"
AGENT_DB_NAME="$AGENT_DB_USER"
DATABASE_URL="postgresql+psycopg2://${AGENT_DB_USER}:${AGENT_DB_PASSWORD}@${PGHOST}:${PGPORT}/${AGENT_DB_NAME}"

log "Creating/updating DB bridge secret: $DB_SECRET_NAME"
run_remote "cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $DB_SECRET_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_URL: '$DATABASE_URL'
  PGHOST: '$PGHOST'
  PGPORT: '$PGPORT'
  PGUSER: '$PGUSER'
  PGPASSWORD: '$PGPASSWORD'
YAML"

log "Generating values file: $VALUES_OUT"
mkdir -p "$(dirname "$VALUES_OUT")"

cat > "$VALUES_OUT" <<YAML
deploymentMode: standalone
id: ${AGENT_ID}

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

persistence:
  existingSecrets:
    database: '${DB_SECRET_NAME}'
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

chmod 600 "$VALUES_OUT"
log "DB bridge secret and generated values file are ready"
