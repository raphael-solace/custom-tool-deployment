#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

mkdir -p "$BUILD_DIR/generated"

NAMESPACE="${NAMESPACE:-default}"
RELEASE_NAME="${RELEASE_NAME:-${AGENT_ID:-example-agent}}"
VALUES_FILE="${VALUES_FILE:-$BUILD_DIR/generated/${RELEASE_NAME}-values.generated.yaml}"
CONFIG_FILE="${CONFIG_FILE:-$BUILD_DIR/generated/${RELEASE_NAME}-config.yaml}"
REMOTE_VALUES="/tmp/${RELEASE_NAME}-values.generated.yaml"
REMOTE_CONFIG="/tmp/${RELEASE_NAME}-config.yaml"

if [[ ! -f "$VALUES_FILE" ]]; then
  log "Missing values file: $VALUES_FILE"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  log "Missing config file: $CONFIG_FILE"
  exit 1
fi

copy_to_remote "$VALUES_FILE" "$REMOTE_VALUES"
copy_to_remote "$CONFIG_FILE" "$REMOTE_CONFIG"

log "Updating Helm repo index"
run_remote "helm repo update solace-agent-mesh >/dev/null"

log "Running server-side dry-run"
run_remote "helm upgrade -i $RELEASE_NAME solace-agent-mesh/sam-agent -n $NAMESPACE -f $REMOTE_VALUES --set-file config.yaml=$REMOTE_CONFIG --dry-run=server >/tmp/${RELEASE_NAME}-dryrun.log"

log "Installing standalone agent release"
run_remote "helm upgrade -i $RELEASE_NAME solace-agent-mesh/sam-agent -n $NAMESPACE -f $REMOTE_VALUES --set-file config.yaml=$REMOTE_CONFIG"

log "Deployment command completed"
