#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

IMAGE_TAR="${IMAGE_TAR:-$ROOT_DIR/artifacts/custom-echo-agent-local-v1.tar}"
REMOTE_TAR="/tmp/custom-echo-agent-local-v1.tar"
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
run_remote_sudo "k3s ctr -n k8s.io images ls | rg 'custom-echo-agent|docker.io/library/custom-echo-agent'"

run_remote "rm -f $REMOTE_TAR"

log "Image import completed"
