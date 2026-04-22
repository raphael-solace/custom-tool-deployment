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
NEW_LLM_SERVICE_API_KEY="${NEW_LLM_SERVICE_API_KEY:-}"
NEW_LLM_GENERAL_MODEL_NAME="${NEW_LLM_GENERAL_MODEL_NAME:-openai/bedrock-anthropic-claude-4-5-opus}"
NEW_LLM_PLANNING_MODEL_NAME="${NEW_LLM_PLANNING_MODEL_NAME:-$NEW_LLM_GENERAL_MODEL_NAME}"
NEW_LLM_REPORT_MODEL_NAME="${NEW_LLM_REPORT_MODEL_NAME:-$NEW_LLM_GENERAL_MODEL_NAME}"

if [[ -z "$NEW_LLM_SERVICE_API_KEY" ]]; then
  log "NEW_LLM_SERVICE_API_KEY is required"
  exit 1
fi

SECRETS=(
  agent-mesh-environment
  quote-planning-agent-env-vars
  sap-joule-agent-env-vars
  shipping-agent-env-vars
  acme-retail-pim-env-vars
  bedrock-legal-agent-env-vars
)

DEPLOYS=(
  quote-planning-agent
  sap-joule-agent
  shipping-agent
  acme-retail-pim
  bedrock-legal-agent
  bedrock-london-local
)

for secret in "${SECRETS[@]}"; do
  exists="$(run_remote "kubectl -n $NAMESPACE get secret $secret >/dev/null 2>&1 && echo yes || true")"
  if [[ "$exists" != "yes" ]]; then
    log "Secret not found, skipping: $secret"
    continue
  fi

  log "Patching secret: $secret"
  escaped_key="${NEW_LLM_SERVICE_API_KEY//"/\\"}"
  escaped_general="${NEW_LLM_GENERAL_MODEL_NAME//"/\\"}"
  escaped_planning="${NEW_LLM_PLANNING_MODEL_NAME//"/\\"}"
  escaped_report="${NEW_LLM_REPORT_MODEL_NAME//"/\\"}"

  run_remote "kubectl -n $NAMESPACE patch secret $secret --type merge -p '{\"stringData\":{\"LLM_SERVICE_API_KEY\":\"$escaped_key\",\"LLM_SERVICE_GENERAL_MODEL_NAME\":\"$escaped_general\",\"LLM_SERVICE_PLANNING_MODEL_NAME\":\"$escaped_planning\",\"LLM_REPORT_MODEL_NAME\":\"$escaped_report\"}}'"
done

for deploy in "${DEPLOYS[@]}"; do
  exists="$(run_remote "kubectl -n $NAMESPACE get deploy $deploy >/dev/null 2>&1 && echo yes || true")"
  if [[ "$exists" != "yes" ]]; then
    log "Deployment not found, skipping restart: $deploy"
    continue
  fi

  log "Restarting deployment: $deploy"
  run_remote "kubectl -n $NAMESPACE rollout restart deploy/$deploy"
  run_remote "kubectl -n $NAMESPACE rollout status deploy/$deploy --timeout=300s"
done

log "RFQ LLM secret sync complete"
