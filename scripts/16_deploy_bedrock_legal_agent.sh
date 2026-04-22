#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

NAMESPACE="${NAMESPACE:-default}"
AGENT_ID="${AGENT_ID:-bedrock-legal-agent}"
RELEASE_NAME="${RELEASE_NAME:-bedrock-legal-agent}"
DB_SECRET_NAME="${DB_SECRET_NAME:-bedrock-legal-agent-db-bridge}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-docker.io/library/bedrock-legal-agent}"
IMAGE_TAG="${IMAGE_TAG:-local-v1}"
VALUES_OUT="${VALUES_OUT:-$ROOT_DIR/deploy/rfq/bedrock-legal-agent-values.generated.yaml}"
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/deploy/rfq/bedrock-legal-agent-config.yaml}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  log "Missing config file: $CONFIG_FILE"
  exit 1
fi

log "Generating values and DB bridge secret for $AGENT_ID"
NAMESPACE="$NAMESPACE" \
AGENT_ID="$AGENT_ID" \
DB_SECRET_NAME="$DB_SECRET_NAME" \
VALUES_OUT="$VALUES_OUT" \
IMAGE_REPOSITORY="$IMAGE_REPOSITORY" \
IMAGE_TAG="$IMAGE_TAG" \
"$SCRIPT_DIR/04_create_db_bridge_secret.sh"

log "Deploying SAM standalone release: $RELEASE_NAME"
NAMESPACE="$NAMESPACE" \
RELEASE_NAME="$RELEASE_NAME" \
VALUES_FILE="$VALUES_OUT" \
CONFIG_FILE="$CONFIG_FILE" \
"$SCRIPT_DIR/05_deploy_agent.sh"

log "Waiting for rollout"
load_local_env
run_remote "kubectl -n $NAMESPACE rollout status deployment/$RELEASE_NAME --timeout=300s"
run_remote "kubectl -n $NAMESPACE get deploy,pod -l app.kubernetes.io/instance=$RELEASE_NAME -o wide"

log "$RELEASE_NAME deployment complete"
