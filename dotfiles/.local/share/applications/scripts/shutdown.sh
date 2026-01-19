#!/usr/bin/env bash

set -euo pipefail

# --- Settings ---
WIN_HOST="192.168.1.82"
WIN_USER="StevendeJong"
LOG="${HOME}/.local/share/shutdown.log"

# Reusable SSH options (key-based login recommended)
SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout=4
  -o StrictHostKeyChecking=accept-new
)

log() { printf '%s %s\n' "$(date +'%F %T')" "$*" | tee -a "$LOG"; }

is_host_up() {
  # Fast ping check
  if ping -c 1 -W 1 "$WIN_HOST" >/dev/null 2>&1; then
    # Optional: check SSH port if netcat is available
    if command -v nc >/dev/null 2>&1; then
      nc -z -w2 "$WIN_HOST" 22 >/dev/null 2>&1
      return $?
    fi
    return 0
  fi
  return 1
}

shutdown_windows() {
  log "Windows host is up; attempting remote shutdown via SSH..."
  if ssh "${SSH_OPTS[@]}" "${WIN_USER}@${WIN_HOST}" "shutdown /s /t 0" >/dev/null 2>&1; then
    log "Sent shutdown to Windows (${WIN_HOST})."
    return 0
  else
    log "WARNING: Failed to send shutdown to Windows (SSH error)."
    return 1
  fi
}

main() {
  mkdir -p "$(dirname "$LOG")"
  log "Starting combined shutdown sequence."

  if is_host_up; then
    shutdown_windows || true
    # small grace so the SSH command can exit cleanly before we go down
    sleep 3
  else
    log "Windows host not reachable; skipping remote shutdown."
  fi

  log "Shutting down this Arch machine..."
  # Use systemd's poweroff for reliability from a desktop context
  systemctl poweroff
}

main "$@"

