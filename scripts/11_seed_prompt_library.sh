#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd jq
require_cmd curl

load_local_env

SAM_API_BASE_URL="${SAM_API_BASE_URL:-http://192.168.32.100/api/v1}"
PROMPTS_FILE="${PROMPTS_FILE:-$ROOT_DIR/deploy/rfq/prompt-library.seed.json}"

if [[ ! -f "$PROMPTS_FILE" ]]; then
  log "Prompt file not found: $PROMPTS_FILE"
  exit 1
fi

count="$(jq 'length' "$PROMPTS_FILE")"
if [[ "$count" -eq 0 ]]; then
  log "No prompts found in: $PROMPTS_FILE"
  exit 0
fi

for ((i=0; i<count; i++)); do
  name="$(jq -r ".[$i].name" "$PROMPTS_FILE")"
  desc="$(jq -r ".[$i].description // empty" "$PROMPTS_FILE")"
  category="$(jq -r ".[$i].category // empty" "$PROMPTS_FILE")"
  command="$(jq -r ".[$i].command // .[$i].name" "$PROMPTS_FILE")"
  prompt_text="$(jq -r ".[$i].promptText" "$PROMPTS_FILE")"

  if [[ -z "$name" || "$name" == "null" ]]; then
    log "Skipping index $i with empty name"
    continue
  fi

  exists_id="$(
    run_remote "curl -s '$SAM_API_BASE_URL/prompts/groups/all' | jq -r --arg n '$name' '.[] | select(.name==\$n) | .id' | head -n1"
  )"

  payload_file="$(mktemp)"
  if [[ -n "$exists_id" && "$exists_id" != "null" ]]; then
    jq -n \
      --arg name "$name" \
      --arg description "$desc" \
      --arg category "$category" \
      --arg command "$command" \
      --arg promptText "$prompt_text" \
      '{
        name: $name,
        description: (if $description == "" then null else $description end),
        category: (if $category == "" then null else $category end),
        command: $command,
        initial_prompt: $promptText
      }' > "$payload_file"

    remote_payload="/tmp/prompt-${name}.json"
    remote_resp="/tmp/prompt-${name}-resp.json"
    copy_to_remote "$payload_file" "$remote_payload"

    http_code="$(run_remote "curl -s -o '$remote_resp' -w '%{http_code}' -X PATCH '$SAM_API_BASE_URL/prompts/groups/$exists_id' -H 'Content-Type: application/json' --data @'$remote_payload'")"
    if [[ "$http_code" != "200" ]]; then
      log "Failed updating prompt $name ($exists_id), http $http_code"
      run_remote "cat '$remote_resp'"
      rm -f "$payload_file"
      exit 1
    fi

    log "Updated prompt: $name ($exists_id)"
    rm -f "$payload_file"
  else
    jq -n \
      --arg name "$name" \
      --arg description "$desc" \
      --arg category "$category" \
      --arg command "$command" \
      --arg promptText "$prompt_text" \
      '{
        name: $name,
        description: (if $description == "" then null else $description end),
        category: (if $category == "" then null else $category end),
        command: $command,
        initial_prompt: $promptText
      }' > "$payload_file"

    remote_payload="/tmp/prompt-${name}.json"
    remote_resp="/tmp/prompt-${name}-resp.json"
    copy_to_remote "$payload_file" "$remote_payload"

    http_code="$(run_remote "curl -s -o '$remote_resp' -w '%{http_code}' -X POST '$SAM_API_BASE_URL/prompts/groups' -H 'Content-Type: application/json' --data @'$remote_payload'")"
    if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
      log "Failed creating prompt $name (http $http_code)"
      run_remote "cat '$remote_resp'"
      rm -f "$payload_file"
      exit 1
    fi

    log "Created prompt: $name"
    rm -f "$payload_file"
  fi
done

log "Final prompt list:"
run_remote "curl -s '$SAM_API_BASE_URL/prompts/groups/all' | jq -r '.[] | [.name, (.category // \"\"), .id] | @tsv'"
