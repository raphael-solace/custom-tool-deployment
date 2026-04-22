#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/local/bin:/usr/bin:/bin:/var/lib/rancher/k3s/data/current/bin
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

LOCK_FILE=/var/lock/k8s1-sam-selfheal.lock
STATE_DIR=/opt/sam-demo-hardening
NAMESPACE=default
EXPECTED_NAMESPACE_ID=solace-agent-mesh-no-auth
SAM_URL=http://192.168.32.100
LOG_FILE=/var/log/k8s1-sam-selfheal.log

mkdir -p "$(dirname "$LOCK_FILE")" "$STATE_DIR" "$(dirname "$LOG_FILE")"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  exit 0
fi

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "$LOG_FILE"
  logger -t k8s1-sam-selfheal -- "$*" || true
}

retry() {
  local attempts="$1"
  local sleep_seconds="$2"
  shift 2
  local i
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    sleep "$sleep_seconds"
  done
  return 1
}

wait_for_cluster() {
  retry 60 5 kubectl get ns >/dev/null 2>&1
}

apply_baseline_resources() {
  kubectl apply -f "$STATE_DIR/sam-joule-path-proxy-config.yaml" >/dev/null
  kubectl apply -f "$STATE_DIR/sam-joule-service.yaml" >/dev/null
}

ensure_deployer_namespace() {
  local current
  current="$(kubectl -n "$NAMESPACE" get deploy agent-mesh-agent-deployer -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="NAMESPACE") | .value // empty')"
  if [[ "$current" != "$EXPECTED_NAMESPACE_ID" ]]; then
    log "patching deployer namespace: '$current' -> '$EXPECTED_NAMESPACE_ID'"
    kubectl -n "$NAMESPACE" set env deploy/agent-mesh-agent-deployer NAMESPACE="$EXPECTED_NAMESPACE_ID" >/dev/null
    echo changed
  else
    echo unchanged
  fi
}

ensure_core_sidecar_patch() {
  kubectl -n "$NAMESPACE" patch deploy agent-mesh-core --patch-file "$STATE_DIR/agent-mesh-core-sam-joule-patch.yaml" >/dev/null || true
}

ensure_s3_init_hardening() {
  kubectl -n "$NAMESPACE" patch deploy agent-mesh-core --patch-file "$STATE_DIR/agent-mesh-core-s3-init-hardening-patch.yaml" >/dev/null || true
}

remove_stale_webui_override() {
  local deploy_json sam_idx mount_idx vol_idx changed=0
  deploy_json="$(kubectl -n "$NAMESPACE" get deploy agent-mesh-core -o json)"
  sam_idx="$(printf '%s' "$deploy_json" | jq '.spec.template.spec.containers | map(.name) | index("sam-core")')"
  if [[ "$sam_idx" == "null" ]]; then
    log "sam-core container not found"
    echo unchanged
    return 0
  fi

  mount_idx="$(printf '%s' "$deploy_json" | jq ".spec.template.spec.containers[$sam_idx].volumeMounts // [] | map(.name) | index(\"webui-index-override\")")"
  if [[ "$mount_idx" != "null" ]]; then
    log "removing stale webui-index-override volumeMount"
    kubectl -n "$NAMESPACE" patch deploy agent-mesh-core --type json -p="[{\"op\":\"remove\",\"path\":\"/spec/template/spec/containers/$sam_idx/volumeMounts/$mount_idx\"}]" >/dev/null
    changed=1
    deploy_json="$(kubectl -n "$NAMESPACE" get deploy agent-mesh-core -o json)"
  fi

  vol_idx="$(printf '%s' "$deploy_json" | jq '.spec.template.spec.volumes // [] | map(.name) | index("webui-index-override")')"
  if [[ "$vol_idx" != "null" ]]; then
    log "removing stale webui-index-override volume"
    kubectl -n "$NAMESPACE" patch deploy agent-mesh-core --type json -p="[{\"op\":\"remove\",\"path\":\"/spec/template/spec/volumes/$vol_idx\"}]" >/dev/null || true
    changed=1
  fi

  if (( changed )); then
    echo changed
  else
    echo unchanged
  fi
}

wait_for_rollout() {
  local deploy="$1"
  kubectl -n "$NAMESPACE" rollout status "deploy/$deploy" --timeout=300s >/dev/null
}

check_ui_assets() {
  local html asset_path
  html="$(curl -fsS --max-time 10 "$SAM_URL/" || true)"
  [[ -n "$html" ]] || return 1
  if grep -q '/sam-joule/assets/' <<<"$html"; then
    return 1
  fi
  asset_path="$(grep -oE '/assets/[^" ]+\.js' <<<"$html" | head -n1 || true)"
  [[ -n "$asset_path" ]] || return 1
  curl -fsS --max-time 10 -o /dev/null "$SAM_URL$asset_path"
}

check_platform_health() {
  curl -fsS --max-time 10 "$SAM_URL/api/v1/platform/health" | jq -e '.status=="healthy"' >/dev/null
}

check_deployer_status() {
  curl -fsS --max-time 10 "$SAM_URL/api/v1/platform/deployers/status" | jq -e '.data.status=="online"' >/dev/null
}

restart_and_wait() {
  local deploy="$1"
  log "restarting deployment/$deploy"
  kubectl -n "$NAMESPACE" rollout restart "deploy/$deploy" >/dev/null
  kubectl -n "$NAMESPACE" rollout status "deploy/$deploy" --timeout=600s >/dev/null
}

main() {
  wait_for_cluster
  apply_baseline_resources
  ensure_core_sidecar_patch
  ensure_s3_init_hardening

  local restart_core=0 restart_deployer=0
  local deployer_patch_result core_patch_result

  deployer_patch_result="$(ensure_deployer_namespace)"
  [[ "$deployer_patch_result" == "changed" ]] && restart_deployer=1

  core_patch_result="$(remove_stale_webui_override)"
  [[ "$core_patch_result" == "changed" ]] && restart_core=1

  if ! retry 3 20 wait_for_rollout agent-mesh-core; then
    log "agent-mesh-core rollout not healthy"
    restart_core=1
  fi

  if ! retry 3 20 wait_for_rollout agent-mesh-agent-deployer; then
    log "agent-mesh-agent-deployer rollout not healthy"
    restart_deployer=1
  fi

  if ! retry 3 10 check_ui_assets; then
    log "UI asset check failed"
    restart_core=1
  fi

  if ! retry 3 10 check_platform_health; then
    log "platform health check failed"
    restart_core=1
  fi

  if ! retry 3 10 check_deployer_status; then
    log "deployer status check failed"
    restart_deployer=1
  fi

  if (( restart_core )); then
    restart_and_wait agent-mesh-core
  fi

  if (( restart_deployer )); then
    restart_and_wait agent-mesh-agent-deployer
  fi

  if (( restart_core || restart_deployer )); then
    retry 12 10 check_platform_health
    retry 12 10 check_deployer_status
    retry 12 10 check_ui_assets
  fi

  check_platform_health
  check_deployer_status
  check_ui_assets
  log "SAM demo self-heal completed successfully"
}

main "$@"
