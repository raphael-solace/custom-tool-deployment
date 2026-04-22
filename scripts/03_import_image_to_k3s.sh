#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

IMAGE_TAR="${IMAGE_TAR:-$BUILD_DIR/images/image.tar}"
REMOTE_TAR="${REMOTE_TAR:-/tmp/$(basename "$IMAGE_TAR")}"
IMAGE_MATCH_PATTERN="${IMAGE_MATCH_PATTERN:-}"
SKIP_COPY="${SKIP_COPY:-false}"

if [[ ! -f "$IMAGE_TAR" ]]; then
  log "Image tar not found: $IMAGE_TAR"
  exit 1
fi

if [[ "$SKIP_COPY" != "true" ]]; then
  log "Copying image tar to remote node"
  copy_to_remote "$IMAGE_TAR" "$REMOTE_TAR"
else
  log "Skipping copy step (SKIP_COPY=true)"
fi

log "Importing image into k3s containerd"
run_remote_sudo "k3s ctr -n k8s.io images import $REMOTE_TAR"

log "Validating imported image"
if [[ -n "$IMAGE_MATCH_PATTERN" ]]; then
  run_remote_sudo "k3s ctr -n k8s.io images ls | rg '$IMAGE_MATCH_PATTERN'"
else
  IMAGE_BASENAME="$(basename "$IMAGE_TAR" .tar)"
  run_remote_sudo "k3s ctr -n k8s.io images ls | rg '$IMAGE_BASENAME'"
fi

run_remote "rm -f $REMOTE_TAR"

log "Image import completed"
