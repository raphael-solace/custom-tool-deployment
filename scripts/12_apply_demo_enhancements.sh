#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd jq
require_cmd curl

load_local_env

NAMESPACE="${NAMESPACE:-default}"
PROJECT_ID="${PROJECT_ID:-4d6045fe-3207-4d4a-9fb9-6f853fd2392f}"
DEFAULT_AGENT_ID="${DEFAULT_AGENT_ID:-QuotePlanningAgent}"
PROMPT_FILE="${PROMPT_FILE:-$ROOT_DIR/deploy/rfq/rfq-project-system-prompt.txt}"
SHIPENGINE_API_KEY="${SHIPENGINE_API_KEY:-}"

if [[ ! -f "$PROMPT_FILE" ]]; then
  log "Prompt file not found: $PROMPT_FILE"
  exit 1
fi

if [[ -n "$SHIPENGINE_API_KEY" ]]; then
  log "Applying new SHIPENGINE_API_KEY to shipping-agent-credentials"
  escaped_key="${SHIPENGINE_API_KEY//"/\\"}"
  run_remote "kubectl -n $NAMESPACE patch secret shipping-agent-credentials --type merge -p '{\"stringData\":{\"SHIPENGINE_API_KEY\":\"$escaped_key\"}}'"
  run_remote "kubectl -n $NAMESPACE rollout restart deploy/shipping-agent"
  run_remote "kubectl -n $NAMESPACE rollout status deploy/shipping-agent --timeout=300s"
else
  log "SHIPENGINE_API_KEY not provided; skipping shipping key update"
fi

log "Seeding prompt library"
"$SCRIPT_DIR/11_seed_prompt_library.sh"

log "Updating RFQ project prompt"
project_json="$(run_remote "curl -s http://192.168.32.100/api/v1/projects/$PROJECT_ID")"
project_name="$(printf '%s' "$project_json" | jq -r '.name // "RFQ Automation"')"
project_desc="$(printf '%s' "$project_json" | jq -r '.description // "RFQ automation that combines LangGraph + Joule"')"
system_prompt="$(cat "$PROMPT_FILE")"

payload_file="$(mktemp)"
jq -n \
  --arg name "$project_name" \
  --arg description "$project_desc" \
  --arg systemPrompt "$system_prompt" \
  --arg defaultAgentId "$DEFAULT_AGENT_ID" \
  '{
    name: $name,
    description: $description,
    systemPrompt: $systemPrompt,
    defaultAgentId: $defaultAgentId
  }' > "$payload_file"

copy_to_remote "$payload_file" /tmp/rfq-project-update-v2.json
http_code="$(run_remote "curl -s -o /tmp/rfq-project-update-v2-resp.json -w '%{http_code}' -X PUT http://192.168.32.100/api/v1/projects/$PROJECT_ID -H 'Content-Type: application/json' --data @/tmp/rfq-project-update-v2.json")"
if [[ "$http_code" != "200" ]]; then
  log "Project update failed (http $http_code)"
  run_remote "cat /tmp/rfq-project-update-v2-resp.json"
  rm -f "$payload_file"
  exit 1
fi

run_remote "cat /tmp/rfq-project-update-v2-resp.json | jq '{id,name,defaultAgentId,updatedAt}'"
rm -f "$payload_file"

log "Demo enhancements complete"
