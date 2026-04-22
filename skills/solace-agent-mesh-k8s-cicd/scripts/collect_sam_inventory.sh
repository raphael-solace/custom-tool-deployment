#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  collect_sam_inventory.sh <namespace> [output-dir]

Creates a lightweight namespace inventory for Solace Agent Mesh investigation.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd kubectl
require_cmd helm

NAMESPACE="$1"
OUT_DIR="${2:-sam-inventory-${NAMESPACE}-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT_DIR"

GREPPER="grep"
if command -v rg >/dev/null 2>&1; then
  GREPPER="rg"
fi

run_to_file() {
  local file="$1"
  shift
  {
    echo "# $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    "$@"
  } > "$OUT_DIR/$file" 2>&1 || true
}

echo "Writing inventory to $OUT_DIR"

run_to_file context.txt kubectl config current-context
run_to_file namespace.txt kubectl get ns "$NAMESPACE" -o yaml
run_to_file helm-list.txt helm list -n "$NAMESPACE"
run_to_file pods.txt kubectl get pods -n "$NAMESPACE" -o wide
run_to_file deployments.txt kubectl get deploy -n "$NAMESPACE" -o wide
run_to_file statefulsets.txt kubectl get sts -n "$NAMESPACE" -o wide
run_to_file daemonsets.txt kubectl get ds -n "$NAMESPACE" -o wide
run_to_file services.txt kubectl get svc -n "$NAMESPACE" -o wide
run_to_file ingress.txt kubectl get ingress -n "$NAMESPACE" -o wide
run_to_file configmaps.txt kubectl get cm -n "$NAMESPACE"
run_to_file secrets.txt kubectl get secret -n "$NAMESPACE"
run_to_file serviceaccounts.txt kubectl get sa -n "$NAMESPACE"
run_to_file roles.txt kubectl get role -n "$NAMESPACE"
run_to_file rolebindings.txt kubectl get rolebinding -n "$NAMESPACE"
run_to_file events.txt kubectl get events -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp

helm list -n "$NAMESPACE" > "$OUT_DIR/helm-list.tmp" 2>/dev/null || true
if [[ -s "$OUT_DIR/helm-list.tmp" ]]; then
  awk 'NR>1 {print $1}' "$OUT_DIR/helm-list.tmp" | while read -r release; do
    [[ -z "$release" ]] && continue
    safe_release="${release//\//_}"
    run_to_file "release-${safe_release}-status.txt" helm status "$release" -n "$NAMESPACE"
    run_to_file "release-${safe_release}-values.yaml" helm get values "$release" -n "$NAMESPACE" -a
  done
fi
rm -f "$OUT_DIR/helm-list.tmp"

{
  echo "Likely SAM workloads:"
  kubectl get deploy,sts -n "$NAMESPACE" 2>/dev/null | $GREPPER -i 'agent-mesh|sam-agent|sam-gateway|gateway|orchestrator' || true
  echo
  echo "Likely SAM services:"
  kubectl get svc -n "$NAMESPACE" 2>/dev/null | $GREPPER -i 'agent-mesh|sam|gateway|platform|auth' || true
  echo
  echo "Likely SAM secrets/config:"
  kubectl get secret,cm -n "$NAMESPACE" 2>/dev/null | $GREPPER -i 'agent-mesh|sam|gateway|broker|oauth|rbac|auth|persistence|seaweed|postgres' || true
} > "$OUT_DIR/likely-sam.txt"

echo "Done: $OUT_DIR"
