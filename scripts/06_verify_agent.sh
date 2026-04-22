#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

mkdir -p "$BUILD_DIR"

NAMESPACE="${NAMESPACE:-default}"
RELEASE_NAME="${RELEASE_NAME:-${AGENT_ID:-example-agent}}"
VERIFY_IMPORT_MODULE="${VERIFY_IMPORT_MODULE:-}"
VERIFY_FUNCTION_NAME="${VERIFY_FUNCTION_NAME:-}"
VERIFY_FUNCTION_ARG="${VERIFY_FUNCTION_ARG:-verify}"
VERIFY_FILE="${VERIFY_FILE:-$BUILD_DIR/verification-${RELEASE_NAME}.txt}"

log "Verifying rollout and runtime health"
run_remote '
set -euo pipefail
kubectl rollout status deployment/'"$RELEASE_NAME"' -n '"$NAMESPACE"' --timeout=240s
echo
echo "== Deployment =="
kubectl get deployment '"$RELEASE_NAME"' -n '"$NAMESPACE"' -o wide
echo
echo "== Pods =="
kubectl get pods -n '"$NAMESPACE"' -l app.kubernetes.io/instance='"$RELEASE_NAME"' -o wide
echo
echo "== db-init logs (tail 80) =="
kubectl logs -n '"$NAMESPACE"' deployment/'"$RELEASE_NAME"' -c db-init --tail=80
echo
echo "== sam logs (tail 120) =="
kubectl logs -n '"$NAMESPACE"' deployment/'"$RELEASE_NAME"' -c sam --tail=120
echo
echo "== Built-in PDF extraction hardening =="
POD=$(kubectl get pods -n '"$NAMESPACE"' -l app.kubernetes.io/instance='"$RELEASE_NAME"' -o jsonpath="{.items[0].metadata.name}")
if kubectl exec -n '"$NAMESPACE"' "$POD" -c sam -- sh -lc "grep -q extract_content_from_artifact_config /app/config/agent.yaml && grep -q application/pdf /app/config/agent.yaml"; then
  echo "pdf_extract_hardening_ok true"
else
  echo "pdf_extract_hardening_ok false"
fi
' | tee "$VERIFY_FILE"

if [[ -n "$VERIFY_IMPORT_MODULE" && -n "$VERIFY_FUNCTION_NAME" ]]; then
  log "Running optional Python import check"
  run_remote '
set -euo pipefail
POD=$(kubectl get pods -n '"$NAMESPACE"' -l app.kubernetes.io/instance='"$RELEASE_NAME"' -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n '"$NAMESPACE"' "$POD" -c sam -- python -c "import importlib; module = importlib.import_module("'"$VERIFY_IMPORT_MODULE"'"); fn = getattr(module, "'"$VERIFY_FUNCTION_NAME"'"); print("import_ok", callable(fn))"
kubectl exec -n '"$NAMESPACE"' "$POD" -c sam -- python -c "import asyncio, importlib; module = importlib.import_module("'"$VERIFY_IMPORT_MODULE"'"); fn = getattr(module, "'"$VERIFY_FUNCTION_NAME"'"); print(asyncio.run(fn("'"$VERIFY_FUNCTION_ARG"'")))"
' | tee -a "$VERIFY_FILE"
else
  printf '
== Python import check ==
skipped
' | tee -a "$VERIFY_FILE"
fi

log "Verification report written to $VERIFY_FILE"
