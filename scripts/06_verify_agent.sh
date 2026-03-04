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
RELEASE_NAME="${RELEASE_NAME:-custom-echo-agent}"
VERIFY_IMPORT_MODULE="${VERIFY_IMPORT_MODULE:-custom_echo_agent.tools}"
VERIFY_FUNCTION_NAME="${VERIFY_FUNCTION_NAME:-healthcheck_echo}"
VERIFY_FUNCTION_ARG="${VERIFY_FUNCTION_ARG:-verify}"
VERIFY_FILE="$ROOT_DIR/deploy/verification-${RELEASE_NAME}.txt"

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
echo "== Python import check =="
POD=$(kubectl get pods -n '"$NAMESPACE"' -l app.kubernetes.io/instance='"$RELEASE_NAME"' -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n '"$NAMESPACE"' "$POD" -c sam -- python -c "import importlib; m = importlib.import_module('"$VERIFY_IMPORT_MODULE"'); print('import_ok', callable(getattr(m, '"$VERIFY_FUNCTION_NAME"')))"
kubectl exec -n '"$NAMESPACE"' "$POD" -c sam -- python -c "import asyncio, importlib; m = importlib.import_module('"$VERIFY_IMPORT_MODULE"'); fn = getattr(m, '"$VERIFY_FUNCTION_NAME"'); print(asyncio.run(fn('"$VERIFY_FUNCTION_ARG"')))"
' | tee "$VERIFY_FILE"

log "Verification report written to $VERIFY_FILE"
