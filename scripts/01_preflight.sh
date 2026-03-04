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
require_cmd docker

load_local_env

log "Running local preflight checks"
docker info >/dev/null

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
