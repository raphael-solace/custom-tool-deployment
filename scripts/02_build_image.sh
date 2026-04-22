#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd docker

docker info >/dev/null

DEFAULT_AGENT_NAME="${AGENT_ID:-sam-agent-package}"
BASE_IMAGE="${BASE_IMAGE:-gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.97.2}"
CUSTOM_IMAGE="${CUSTOM_IMAGE:-docker.io/library/${DEFAULT_AGENT_NAME}:local-v1}"
BASE_TAR="$BUILD_DIR/base-enterprise-1.97.2.tar"
IMAGE_TAR="${IMAGE_TAR:-$BUILD_DIR/images/${DEFAULT_AGENT_NAME}-local-v1.tar}"
AGENT_SOURCE_DIR="${AGENT_SOURCE_DIR:-$ROOT_DIR/packages/custom-joule-agent}"
IMAGE_DISTRIBUTION_MODE="${IMAGE_DISTRIBUTION_MODE:-k3s}" # k3s | registry
PUSH_IMAGE="${PUSH_IMAGE:-false}"
IMAGE_PLATFORM="${IMAGE_PLATFORM:-linux/amd64}"
AUTO_INSTALL_BINFMT="${AUTO_INSTALL_BINFMT:-true}"

mkdir -p "$BUILD_DIR" "$BUILD_DIR/images"

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

log "Ensuring base image for target platform $IMAGE_PLATFORM: $BASE_IMAGE"
if ! docker pull --platform "$IMAGE_PLATFORM" "$BASE_IMAGE" >/dev/null 2>&1; then
  if [[ "$IMAGE_DISTRIBUTION_MODE" == "k3s" ]]; then
    log "Direct pull failed, exporting base image from k3s node"
    run_remote_sudo "k3s ctr -n k8s.io images export /tmp/base-enterprise-1.97.2.tar $BASE_IMAGE"
    copy_from_remote /tmp/base-enterprise-1.97.2.tar "$BASE_TAR"
    run_remote "rm -f /tmp/base-enterprise-1.97.2.tar"
    docker load -i "$BASE_TAR" >/dev/null
  elif docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
    log "Using local cached base image because pull failed"
  else
    log "Unable to pull base image in registry mode: $BASE_IMAGE"
    log "Authenticate to registry or pre-load the base image locally and retry."
    exit 1
  fi
fi

TARGET_ARCH="${IMAGE_PLATFORM##*/}"
if ! docker run --rm --platform "$IMAGE_PLATFORM" --entrypoint /bin/sh "$BASE_IMAGE" -c "true" >/dev/null 2>&1; then
  log "Cross-platform runtime for $IMAGE_PLATFORM is unavailable on this machine"

  if [[ "$AUTO_INSTALL_BINFMT" == "true" ]]; then
    log "Attempting to install binfmt emulator for $TARGET_ARCH"
    docker run --privileged --rm tonistiigi/binfmt --install "$TARGET_ARCH" >/dev/null 2>&1 || true
  fi

  if ! docker run --rm --platform "$IMAGE_PLATFORM" --entrypoint /bin/sh "$BASE_IMAGE" -c "true" >/dev/null 2>&1; then
    log "Cross-platform runtime still unavailable for $IMAGE_PLATFORM"
    log "Run once: docker run --privileged --rm tonistiigi/binfmt --install $TARGET_ARCH"
    log "Then retry this script."
    exit 1
  fi
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" == "registry" && "$PUSH_IMAGE" == "true" ]]; then
  log "Building and pushing image to registry: $CUSTOM_IMAGE"
  docker buildx build --platform "$IMAGE_PLATFORM" --pull --push -t "$CUSTOM_IMAGE" "$AGENT_SOURCE_DIR"
else
  log "Building custom image locally: $CUSTOM_IMAGE"
  docker buildx build --platform "$IMAGE_PLATFORM" --pull --load -t "$CUSTOM_IMAGE" "$AGENT_SOURCE_DIR"
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" == "k3s" ]]; then
  log "Saving image tar for k3s import: $IMAGE_TAR"
  docker save "$CUSTOM_IMAGE" -o "$IMAGE_TAR"
else
  log "Registry mode selected; skipping local tar export"
fi

log "Image build/export completed"
