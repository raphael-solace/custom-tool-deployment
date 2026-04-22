#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd jq
require_cmd curl

SAM_API_BASE_URL="${SAM_API_BASE_URL:-http://192.168.32.100/api/v1}"
PROJECT_ID="${PROJECT_ID:-4d6045fe-3207-4d4a-9fb9-6f853fd2392f}"
AGENT_NAME="${AGENT_NAME:-QuotePlanningAgent}"
PROMPTS_FILE="${PROMPTS_FILE:-$ROOT_DIR/deploy/rfq/prompt-library.seed.json}"
VERIFY_DIR="${VERIFY_DIR:-$BUILD_DIR/rfq-scenario-verification}"
VERIFY_SUMMARY="${VERIFY_SUMMARY:-$VERIFY_DIR/verification-rfp-scenarios.txt}"
AUTO_FIX_MAT_SKUS="${AUTO_FIX_MAT_SKUS:-true}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-900}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-5}"

MARKER_1="Requested SKUs do not exist in Acme product catalog - no MAT- prefix SKUs found in database"
MARKER_2="Cannot proceed with SAP Joule sourcing or ShippingAgent queries without valid product identifiers"
MARKER_3="Pricing data unavailable in PIM for any products"

mkdir -p "$VERIFY_DIR"
: > "$VERIFY_SUMMARY"

if [[ ! -f "$PROMPTS_FILE" ]]; then
  log "Prompts file not found: $PROMPTS_FILE"
  exit 1
fi

SCENARIOS=()
while IFS= read -r scenario; do
  [[ -z "$scenario" ]] && continue
  SCENARIOS+=("$scenario")
done < <(jq -r '.[] | select(.name | test("^RFP[0-9]+$")) | .name' "$PROMPTS_FILE" | sort -V)

if [[ "${#SCENARIOS[@]}" -eq 0 ]]; then
  log "No RFP scenarios found in $PROMPTS_FILE"
  exit 1
fi

log "Testing scenarios: ${SCENARIOS[*]}"

declare -a NEEDS_FIX=()
FINAL_STATUS=()
for _ in "${SCENARIOS[@]}"; do
  FINAL_STATUS+=("unknown")
done

set_status() {
  local scenario="$1"
  local status="$2"
  local i
  for ((i=0; i<${#SCENARIOS[@]}; i++)); do
    if [[ "${SCENARIOS[$i]}" == "$scenario" ]]; then
      FINAL_STATUS[$i]="$status"
      return 0
    fi
  done
  return 1
}

get_status() {
  local scenario="$1"
  local i
  for ((i=0; i<${#SCENARIOS[@]}; i++)); do
    if [[ "${SCENARIOS[$i]}" == "$scenario" ]]; then
      printf '%s' "${FINAL_STATUS[$i]}"
      return 0
    fi
  done
  printf 'unknown'
}

generate_payload() {
  local scenario="$1"
  local session_id="$2"
  local payload_file="$3"
  local prompt_text

  prompt_text="$(jq -r --arg n "$scenario" '.[] | select(.name == $n) | .promptText' "$PROMPTS_FILE")"
  if [[ -z "$prompt_text" || "$prompt_text" == "null" ]]; then
    log "Scenario not found in prompt file: $scenario"
    return 1
  fi

  jq -n \
    --arg id "${scenario}-$(date +%s)" \
    --arg sid "$session_id" \
    --arg msgid "msg-${session_id}-1" \
    --arg text "$prompt_text" \
    --arg project "$PROJECT_ID" \
    --arg agent "$AGENT_NAME" \
    '{
      id: $id,
      jsonrpc: "2.0",
      method: "message/send",
      params: {
        configuration: { blocking: true },
        message: {
          contextId: $sid,
          messageId: $msgid,
          role: "user",
          parts: [
            { kind: "text", text: $text }
          ],
          metadata: {
            projectId: $project,
            agent_name: $agent
          }
        },
        metadata: {
          projectId: $project,
          agent_name: $agent
        }
      }
    }' > "$payload_file"
}

run_one() {
  local scenario="$1"
  local pass="$2"
  local scenario_slug
  scenario_slug="$(printf '%s' "$scenario" | tr '[:upper:]' '[:lower:]')"
  local session_id="web-session-${scenario_slug}-$(date +%s)-$RANDOM"
  local payload_file
  payload_file="$(mktemp)"
  local resp_file
  resp_file="$(mktemp)"
  local events_file
  events_file="$(mktemp)"

  generate_payload "$scenario" "$session_id" "$payload_file"

  local http_code
  log "Scenario $scenario ($pass): submitting request"
  http_code="$(
    curl -sS \
      --connect-timeout 10 \
      --max-time 180 \
      -o "$resp_file" \
      -w '%{http_code}' \
      -X POST "$SAM_API_BASE_URL/message:send" \
      -H 'Content-Type: application/json' \
      --data @"$payload_file"
  )"
  if [[ "$http_code" != "200" ]]; then
    log "Scenario $scenario ($pass): message:send failed (http $http_code)"
    cat "$resp_file" || true
    rm -f "$payload_file" "$resp_file" "$events_file"
    set_status "$scenario" "failed-send"
    return 1
  fi

  local task_id
  task_id="$(jq -r '.result.id // empty' "$resp_file")"
  if [[ -z "$task_id" ]]; then
    log "Scenario $scenario ($pass): missing task id"
    cat "$resp_file" || true
    rm -f "$payload_file" "$resp_file" "$events_file"
    set_status "$scenario" "failed-no-task"
    return 1
  fi

  log "Scenario $scenario ($pass): task_id=$task_id"
  local task_state=""
  local running="true"
  local elapsed=0
  while (( elapsed < MAX_WAIT_SECONDS )); do
    local status_raw
    status_raw="$(
      curl -sS \
        --connect-timeout 10 \
        --max-time 30 \
        "$SAM_API_BASE_URL/tasks/$task_id/status" \
        || true
    )"

    running="$(printf '%s' "$status_raw" | rg -o '"is_running":(true|false)' | head -n1 | cut -d: -f2 || true)"
    task_state="$(printf '%s' "$status_raw" | rg -o '"status":"(completed|failed|canceled)"' | head -n1 | sed -E 's/.*"status":"([^"]+)".*/\1/' || true)"

    if [[ "$running" == "false" ]]; then
      if [[ -z "$task_state" ]]; then
        task_state="completed"
      fi
      break
    fi

    if (( elapsed > 0 && elapsed % 60 == 0 )); then
      log "Scenario $scenario ($pass): waiting (${elapsed}s/${MAX_WAIT_SECONDS}s)"
    fi

    sleep "$POLL_INTERVAL_SECONDS"
    elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
  done

  if [[ "$running" == "true" ]]; then
    log "Scenario $scenario ($pass): timeout after ${MAX_WAIT_SECONDS}s"
    set_status "$scenario" "failed-timeout"
    rm -f "$payload_file" "$resp_file" "$events_file"
    return 1
  fi

  curl -sS \
    --connect-timeout 10 \
    --max-time 180 \
    "$SAM_API_BASE_URL/tasks/$task_id/events?offset=0&limit=5000" \
    > "$events_file"

  local response_text
  response_text="$(
    jq -r --arg id "$task_id" --arg source "$AGENT_NAME" '
      .tasks[$id].events[]?
      | select(.source_entity == $source and .direction == "task" and .full_payload.result.status.state == "completed")
      | ((.full_payload.result.status.message.parts // [])
         | map(select(.kind == "text") | .text)
         | join("\n"))
    ' "$events_file" | awk 'NF {print; found=1} END {if (!found) print ""}'
  )"

  if [[ -z "$response_text" ]]; then
    response_text="$(
      jq -r --arg id "$task_id" --arg source "$AGENT_NAME" '
        .tasks[$id].events[]?
        | select(.source_entity == $source and .direction == "status-update" and .full_payload.result.final == true)
        | ((.full_payload.result.status.message.parts // [])
           | map(select(.kind == "text") | .text)
           | join("\n"))
      ' "$events_file" | awk 'NF {print; found=1} END {if (!found) print ""}'
    )"
  fi

  local verify_file="$VERIFY_DIR/verification-${scenario_slug}-${pass}.txt"
  {
    echo "scenario=$scenario"
    echo "pass=$pass"
    echo "session_id=$session_id"
    echo "task_id=$task_id"
    echo "task_state=$task_state"
    echo
    echo "--- prompt ---"
    jq -r --arg n "$scenario" '.[] | select(.name == $n) | .promptText' "$PROMPTS_FILE"
    echo
    echo "--- response ---"
    printf '%s\n' "$response_text"
  } > "$verify_file"

  printf '%s\n' "[$scenario][$pass] task_state=$task_state file=$verify_file" >> "$VERIFY_SUMMARY"

  if [[ "$task_state" != "completed" ]]; then
    set_status "$scenario" "failed-task-state-$task_state"
    return 1
  fi

  if [[ -z "$response_text" ]]; then
    set_status "$scenario" "failed-empty-response"
    return 1
  fi

  if grep -Fq "$MARKER_1" "$verify_file" || grep -Fq "$MARKER_2" "$verify_file" || grep -Fq "$MARKER_3" "$verify_file"; then
    set_status "$scenario" "failed-missing-mat-skus"
    rm -f "$payload_file" "$resp_file" "$events_file"
    return 2
  fi

  set_status "$scenario" "passed"
  rm -f "$payload_file" "$resp_file" "$events_file"
  return 0
}

for scenario in "${SCENARIOS[@]}"; do
  set +e
  run_one "$scenario" "initial"
  rc=$?
  set -e
  if [[ $rc -eq 2 ]]; then
    NEEDS_FIX+=("$scenario")
  elif [[ $rc -ne 0 ]]; then
    log "Scenario $scenario failed on initial pass"
  fi
done

if [[ "${#NEEDS_FIX[@]}" -gt 0 && "$AUTO_FIX_MAT_SKUS" == "true" ]]; then
  log "Detected MAT SKU/PIM gap in scenarios: ${NEEDS_FIX[*]}"
  log "Applying automatic SKU seed fix"
  "$SCRIPT_DIR/18_seed_rfp_mat_skus.sh"

  for scenario in "${NEEDS_FIX[@]}"; do
    set +e
    run_one "$scenario" "after-seed"
    rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      log "Scenario $scenario still failing after SKU seed"
    fi
  done
fi

printf '%s\n' "" >> "$VERIFY_SUMMARY"
printf '%s\n' "=== Final Status ===" >> "$VERIFY_SUMMARY"
for scenario in "${SCENARIOS[@]}"; do
  printf '%s\n' "$scenario=$(get_status "$scenario")" >> "$VERIFY_SUMMARY"
done

cat "$VERIFY_SUMMARY"

for scenario in "${SCENARIOS[@]}"; do
  status="$(get_status "$scenario")"
  if [[ "$status" != "passed" ]]; then
    exit 1
  fi
done

log "All RFP scenarios passed"
