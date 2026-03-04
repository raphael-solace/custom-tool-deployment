#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect
require_cmd kubectl
require_cmd helm
require_cmd jq

SKIP_DOCKER_CHECK="${SKIP_DOCKER_CHECK:-false}"
if [[ "$SKIP_DOCKER_CHECK" != "true" ]]; then
  require_cmd docker
fi

load_local_env

log "Running local preflight checks"
if [[ "$SKIP_DOCKER_CHECK" != "true" ]]; then
  docker info >/dev/null
fi

BASELINE_FILE="$ROOT_DIR/deploy/baseline-snapshot.txt"
log "Capturing baseline cluster snapshot to $BASELINE_FILE"
run_remote '
set -euo pipefail
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Context: $(kubectl config current-context)"
echo
echo "== Helm Repos =="
helm repo list
echo
echo "== Service Account =="
kubectl get sa solace-agent-mesh-sa -n default
echo
echo "== RoleBinding Subject =="
kubectl get rolebinding agent-mesh-rolebinding-sam -n default -o jsonpath="{.subjects[*].kind} {.subjects[*].name} {.subjects[*].namespace}{\"\\n\"}"
echo
echo "== Existing SAM Releases =="
helm list -n default
echo
echo "== Existing SAM Deployments =="
kubectl get deploy -n default | rg -i "agent-mesh|sam-agent|sam-gateway" || true
' | tee "$BASELINE_FILE"

log "Preflight completed"
