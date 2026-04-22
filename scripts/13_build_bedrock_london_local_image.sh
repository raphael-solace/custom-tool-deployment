#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd docker

docker info >/dev/null

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-docker.io/library/bedrock-london-local}"
IMAGE_TAG="${IMAGE_TAG:-local-v1}"
IMAGE_PLATFORM="${IMAGE_PLATFORM:-linux/amd64}"
IMAGE_TAR="${IMAGE_TAR:-$BUILD_DIR/images/bedrock-london-local-${IMAGE_TAG}.tar}"
SOURCE_DIR="${SOURCE_DIR:-$ROOT_DIR/runtimes/bedrock-london-local}"

if [[ ! -f "$SOURCE_DIR/Dockerfile" || ! -f "$SOURCE_DIR/app.py" ]]; then
  log "Missing bedrock-london-local source files under $SOURCE_DIR"
  exit 1
fi

mkdir -p "$BUILD_DIR/images"

IMAGE_REF="${IMAGE_REPOSITORY}:${IMAGE_TAG}"

log "Building bedrock-london-local image: $IMAGE_REF"
docker buildx build --platform "$IMAGE_PLATFORM" --pull --load -t "$IMAGE_REF" "$SOURCE_DIR"

log "Saving image tar: $IMAGE_TAR"
docker save "$IMAGE_REF" -o "$IMAGE_TAR"

log "Image build complete"
