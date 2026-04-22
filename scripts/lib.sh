#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
LOG_DIR="${LOG_DIR:-$BUILD_DIR/logs}"
mkdir -p "$LOG_DIR" "$BUILD_DIR"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    log "Missing required command: $cmd"
    exit 1
  }
}

load_local_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    log "Missing env file: $ENV_FILE"
    exit 1
  fi

  SSH_TARGET="$(awk 'NR==1{sub(/^ssh[[:space:]]+/, ""); print}' "$ENV_FILE")"
  SSH_PASS="$(awk -F'pwd:[[:space:]]*' 'NR==2{print $2}' "$ENV_FILE")"

  if [[ -z "$SSH_TARGET" ]]; then
    log "Could not parse SSH target from $ENV_FILE"
    exit 1
  fi

  export SSH_TARGET SSH_PASS BUILD_DIR LOG_DIR
}

run_remote() {
  local cmd="$1"
  local bootstrap='if [[ -f "$HOME/.kube/config" ]]; then export KUBECONFIG="$HOME/.kube/config"; fi; '
  local wrapped_cmd="${bootstrap}${cmd}"

  if [[ -n "${SSH_PASS:-}" ]]; then
    local cmd_b64
    cmd_b64="$(printf '%s' "$wrapped_cmd" | base64 | tr -d '\n')"
    SSH_TARGET="$SSH_TARGET" SSH_PASS="$SSH_PASS" CMD_B64="$cmd_b64" expect <<'EOEXPECT'
set timeout -1
set target $env(SSH_TARGET)
set pass $env(SSH_PASS)
set cmd_b64 $env(CMD_B64)
set output ""
log_user 0
spawn ssh -o StrictHostKeyChecking=accept-new $target "echo $cmd_b64 | base64 -d | bash"
expect {
  -re "(?i)password:" {
    send "$pass\r"
    exp_continue
  }
  eof {
    set output $expect_out(buffer)
  }
}
set clean $output
regsub -all {Connection to [^\n]* closed\.\n?} $clean "" clean
regsub -all {bash: warning: setlocale: LC_ALL: cannot change locale \(en_US\.UTF-8\)\n?} $clean "" clean
regsub -all {bash: warning: setlocale: LC_CTYPE: cannot change locale \([^\)]*\)\n?} $clean "" clean
regsub -all {bash: warning: setlocale: LANG: cannot change locale \([^\)]*\)\n?} $clean "" clean
regsub -all {\r} $clean "" clean
regsub {^\n+} $clean "" clean
set clean [string trim $clean]
puts $clean
catch wait result
set exit_status [lindex $result 3]
exit $exit_status
EOEXPECT
  else
    ssh -o StrictHostKeyChecking=accept-new "$SSH_TARGET" "bash -lc $(printf '%q' "$wrapped_cmd")"
  fi
}

run_remote_sudo() {
  local cmd="$1"

  if [[ -n "${SSH_PASS:-}" ]]; then
    run_remote "printf '%s\n' '$SSH_PASS' | sudo -S -p '' bash -lc $(printf '%q' "$cmd")"
  else
    run_remote "sudo bash -lc $(printf '%q' "$cmd")"
  fi
}

copy_to_remote() {
  local src="$1"
  local dst="$2"

  if [[ -n "${SSH_PASS:-}" ]]; then
    SSH_TARGET="$SSH_TARGET" SSH_PASS="$SSH_PASS" SRC="$src" DST="$dst" expect <<'EOEXPECT'
set timeout -1
set target $env(SSH_TARGET)
set pass $env(SSH_PASS)
set src $env(SRC)
set dst $env(DST)
spawn scp -o StrictHostKeyChecking=accept-new $src $target:$dst
expect {
  -re "(?i)password:" { send "$pass\r"; exp_continue }
  eof
}
catch wait result
set exit_status [lindex $result 3]
exit $exit_status
EOEXPECT
  else
    scp -o StrictHostKeyChecking=accept-new "$src" "$SSH_TARGET:$dst"
  fi
}

copy_from_remote() {
  local src="$1"
  local dst="$2"

  if [[ -n "${SSH_PASS:-}" ]]; then
    SSH_TARGET="$SSH_TARGET" SSH_PASS="$SSH_PASS" SRC="$src" DST="$dst" expect <<'EOEXPECT'
set timeout -1
set target $env(SSH_TARGET)
set pass $env(SSH_PASS)
set src $env(SRC)
set dst $env(DST)
spawn scp -o StrictHostKeyChecking=accept-new $target:$src $dst
expect {
  -re "(?i)password:" { send "$pass\r"; exp_continue }
  eof
}
catch wait result
set exit_status [lindex $result 3]
exit $exit_status
EOEXPECT
  else
    scp -o StrictHostKeyChecking=accept-new "$SSH_TARGET:$src" "$dst"
  fi
}

yaml_single_quote_escape() {
  sed "s/'/''/g"
}
