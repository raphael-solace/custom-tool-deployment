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
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-docker.io/library/bedrock-london-local}"
IMAGE_TAG="${IMAGE_TAG:-local-v1}"
IMAGE_TAR="${IMAGE_TAR:-$BUILD_DIR/images/bedrock-london-local-${IMAGE_TAG}.tar}"
MANIFEST_FILE="${MANIFEST_FILE:-$ROOT_DIR/deploy/rfq/bedrock-london-local.yaml}"

if [[ ! -f "$IMAGE_TAR" ]]; then
  log "Image tar not found: $IMAGE_TAR"
  exit 1
fi

if [[ ! -f "$MANIFEST_FILE" ]]; then
  log "Manifest file not found: $MANIFEST_FILE"
  exit 1
fi

log "Importing bedrock-london-local image into k3s"
IMAGE_TAR="$IMAGE_TAR" IMAGE_MATCH_PATTERN="bedrock-london-local|${IMAGE_REPOSITORY}" "$SCRIPT_DIR/03_import_image_to_k3s.sh"

log "Applying k8s manifests for bedrock-london-local"
copy_to_remote "$MANIFEST_FILE" /tmp/bedrock-london-local.yaml
run_remote "kubectl apply -f /tmp/bedrock-london-local.yaml"
run_remote "kubectl -n $NAMESPACE set image deployment/bedrock-london-local bedrock-london-local=${IMAGE_REPOSITORY}:${IMAGE_TAG}"
run_remote "kubectl -n $NAMESPACE rollout status deployment/bedrock-london-local --timeout=300s"

log "Runtime deployment status"
run_remote "kubectl -n $NAMESPACE get deploy,svc,pod -l app.kubernetes.io/name=bedrock-london-local -o wide"

log "bedrock-london-local deployment complete"
