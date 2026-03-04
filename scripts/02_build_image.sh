#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd docker

docker info >/dev/null

BASE_IMAGE="${BASE_IMAGE:-gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45}"
CUSTOM_IMAGE="${CUSTOM_IMAGE:-docker.io/library/custom-echo-agent:local-v1}"
BASE_TAR="$ROOT_DIR/artifacts/base-enterprise-1.65.45.tar"
IMAGE_TAR="${IMAGE_TAR:-$ROOT_DIR/artifacts/custom-echo-agent-local-v1.tar}"
AGENT_SOURCE_DIR="${AGENT_SOURCE_DIR:-$ROOT_DIR/custom-echo-agent}"
IMAGE_DISTRIBUTION_MODE="${IMAGE_DISTRIBUTION_MODE:-k3s}" # k3s | registry
PUSH_IMAGE="${PUSH_IMAGE:-false}"

mkdir -p "$ROOT_DIR/artifacts"

if [[ ! -f "$AGENT_SOURCE_DIR/Dockerfile" ]]; then
  log "Missing Dockerfile in agent source dir: $AGENT_SOURCE_DIR"
  exit 1
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" != "k3s" && "$IMAGE_DISTRIBUTION_MODE" != "registry" ]]; then
  log "Unsupported IMAGE_DISTRIBUTION_MODE: $IMAGE_DISTRIBUTION_MODE (expected: k3s|registry)"
  exit 1
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" == "k3s" ]]; then
  require_cmd expect
  require_cmd ssh
  require_cmd scp
  load_local_env
fi

if ! docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
  log "Base image not present locally, attempting pull: $BASE_IMAGE"
  if ! docker pull "$BASE_IMAGE"; then
    if [[ "$IMAGE_DISTRIBUTION_MODE" == "k3s" ]]; then
      log "Direct pull failed, exporting base image from k3s node"
      run_remote_sudo "k3s ctr -n k8s.io images export /tmp/base-enterprise-1.65.45.tar $BASE_IMAGE"
      copy_from_remote /tmp/base-enterprise-1.65.45.tar "$BASE_TAR"
      run_remote "rm -f /tmp/base-enterprise-1.65.45.tar"
      docker load -i "$BASE_TAR" >/dev/null
    else
      log "Unable to pull base image in registry mode: $BASE_IMAGE"
      log "Authenticate to registry or pre-load the base image locally and retry."
      exit 1
    fi
  fi
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" == "registry" && "$PUSH_IMAGE" == "true" ]]; then
  log "Building and pushing image to registry: $CUSTOM_IMAGE"
  docker buildx build --platform linux/amd64 --push -t "$CUSTOM_IMAGE" "$AGENT_SOURCE_DIR"
else
  log "Building custom image locally: $CUSTOM_IMAGE"
  docker buildx build --platform linux/amd64 --load -t "$CUSTOM_IMAGE" "$AGENT_SOURCE_DIR"
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" == "k3s" ]]; then
  log "Saving image tar for k3s import: $IMAGE_TAR"
  docker save "$CUSTOM_IMAGE" -o "$IMAGE_TAR"
else
  log "Registry mode selected; skipping local tar export"
fi

log "Image build/export completed"
