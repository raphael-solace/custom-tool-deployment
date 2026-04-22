#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

AGENT_SOURCE_DIR="${AGENT_SOURCE_DIR:-$ROOT_DIR/packages/custom-bedrock-legal-agent}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-docker.io/library/bedrock-legal-agent}"
IMAGE_TAG="${IMAGE_TAG:-local-v1}"
CUSTOM_IMAGE="${CUSTOM_IMAGE:-${IMAGE_REPOSITORY}:${IMAGE_TAG}}"
IMAGE_TAR="${IMAGE_TAR:-$BUILD_DIR/images/bedrock-legal-agent-${IMAGE_TAG}.tar}"
IMAGE_PLATFORM="${IMAGE_PLATFORM:-linux/amd64}"

if [[ ! -f "$AGENT_SOURCE_DIR/Dockerfile" ]]; then
  log "Missing Dockerfile in $AGENT_SOURCE_DIR"
  exit 1
fi

log "Building SAM image with sam_bedrock_agent module"
AGENT_SOURCE_DIR="$AGENT_SOURCE_DIR" \
CUSTOM_IMAGE="$CUSTOM_IMAGE" \
IMAGE_TAR="$IMAGE_TAR" \
IMAGE_PLATFORM="$IMAGE_PLATFORM" \
IMAGE_DISTRIBUTION_MODE="k3s" \
PUSH_IMAGE="false" \
"$SCRIPT_DIR/02_build_image.sh"

log "Importing bedrock-legal-agent image into k3s"
IMAGE_TAR="$IMAGE_TAR" IMAGE_MATCH_PATTERN="bedrock-legal-agent|${IMAGE_REPOSITORY}" "$SCRIPT_DIR/03_import_image_to_k3s.sh"

log "Build/import complete for $CUSTOM_IMAGE"
