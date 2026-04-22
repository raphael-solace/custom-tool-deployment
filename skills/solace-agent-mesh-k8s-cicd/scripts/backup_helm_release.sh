#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  backup_helm_release.sh <namespace> <release> [output-dir]

Backs up Helm and Kubernetes state for one release before a change.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 2 ]]; then
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
RELEASE="$2"
OUT_DIR="${3:-sam-backup-${RELEASE}-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT_DIR"

label_selector="app.kubernetes.io/instance=${RELEASE}"

echo "Backing up $RELEASE in namespace $NAMESPACE to $OUT_DIR"

helm status "$RELEASE" -n "$NAMESPACE" > "$OUT_DIR/helm-status.txt" 2>&1 || true
helm get values "$RELEASE" -n "$NAMESPACE" -a > "$OUT_DIR/helm-values.yaml" 2>&1 || true
helm get manifest "$RELEASE" -n "$NAMESPACE" > "$OUT_DIR/helm-manifest.yaml" 2>&1 || true
helm get notes "$RELEASE" -n "$NAMESPACE" > "$OUT_DIR/helm-notes.txt" 2>&1 || true
helm history "$RELEASE" -n "$NAMESPACE" > "$OUT_DIR/helm-history.txt" 2>&1 || true

kubectl get all -n "$NAMESPACE" -l "$label_selector" -o wide > "$OUT_DIR/kubectl-all.txt" 2>&1 || true
kubectl get cm,secret,ingress,sa,role,rolebinding -n "$NAMESPACE" -l "$label_selector" > "$OUT_DIR/kubectl-config.txt" 2>&1 || true
kubectl describe all -n "$NAMESPACE" -l "$label_selector" > "$OUT_DIR/kubectl-describe-all.txt" 2>&1 || true
kubectl get pods -n "$NAMESPACE" -l "$label_selector" -o name > "$OUT_DIR/pods.txt" 2>&1 || true

if [[ -s "$OUT_DIR/pods.txt" ]]; then
  while read -r pod; do
    [[ -z "$pod" ]] && continue
    pod_name="${pod#pod/}"
    kubectl describe "$pod" -n "$NAMESPACE" > "$OUT_DIR/${pod_name}-describe.txt" 2>&1 || true
    kubectl logs "$pod" -n "$NAMESPACE" --all-containers --tail=300 > "$OUT_DIR/${pod_name}-logs.txt" 2>&1 || true
  done < "$OUT_DIR/pods.txt"
fi

echo "Done: $OUT_DIR"
