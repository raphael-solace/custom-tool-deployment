#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd jq
require_cmd curl

load_local_env

REMOTE_DIR="${REMOTE_DIR:-/opt/sam-demo-hardening}"
SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"

FILES=(
  "$ROOT_DIR/deploy/hardening/sam-joule-service.yaml"
  "$ROOT_DIR/deploy/hardening/sam-joule-path-proxy-config.yaml"
  "$ROOT_DIR/deploy/hardening/agent-mesh-core-sam-joule-patch.yaml"
  "$ROOT_DIR/deploy/hardening/agent-mesh-core-s3-init-hardening-patch.yaml"
  "$ROOT_DIR/deploy/hardening/k8s1-sam-selfheal.sh"
  "$ROOT_DIR/deploy/hardening/k8s1-sam-selfheal.service"
  "$ROOT_DIR/deploy/hardening/k8s1-sam-selfheal.timer"
)

log "Creating remote hardening directory: $REMOTE_DIR"
run_remote_sudo "mkdir -p '$REMOTE_DIR'"

for file in "${FILES[@]}"; do
  remote_path="$REMOTE_DIR/$(basename "$file")"
  log "Copying $(basename "$file")"
  copy_to_remote "$file" "/tmp/$(basename "$file")"
  run_remote_sudo "install -m 0644 '/tmp/$(basename "$file")' '$remote_path'"
done

run_remote_sudo "install -m 0755 '$REMOTE_DIR/k8s1-sam-selfheal.sh' /usr/local/bin/k8s1-sam-selfheal.sh"
run_remote_sudo "install -m 0644 '$REMOTE_DIR/k8s1-sam-selfheal.service' '$SYSTEMD_DIR/k8s1-sam-selfheal.service'"
run_remote_sudo "install -m 0644 '$REMOTE_DIR/k8s1-sam-selfheal.timer' '$SYSTEMD_DIR/k8s1-sam-selfheal.timer'"

log "Reloading systemd and enabling self-heal timer"
run_remote_sudo "systemctl daemon-reload && systemctl enable --now k8s1-sam-selfheal.timer"

log "Running self-heal once now"
run_remote_sudo "/usr/local/bin/k8s1-sam-selfheal.sh"

log "Verifying timer and platform health"
run_remote_sudo "systemctl --no-pager --full status k8s1-sam-selfheal.timer | sed -n '1,20p'"
run_remote_sudo "systemctl --no-pager --full status k8s1-sam-selfheal.service | sed -n '1,40p' || true"
run_remote "curl -s http://192.168.32.100/api/v1/platform/health && echo && curl -s http://192.168.32.100/api/v1/platform/deployers/status && echo && python3 - <<\"PY\"
import re,urllib.request
html=urllib.request.urlopen(\"http://192.168.32.100/\", timeout=10).read().decode()
m=re.search(r\"/assets/[^\\\" ]+\\.js\", html)
print(m.group(0) if m else \"NO_ASSET\")
PY"

log "K8S1 demo hardening installed"
