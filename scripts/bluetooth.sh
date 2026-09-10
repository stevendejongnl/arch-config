#!/usr/bin/env bash
# Bluetooth stack setup.
#   - deploy the btusb no-autosuspend modprobe drop-in (fixes the Intel
#     AX200 "hci0: Reading Intel version command failed (-110)" init timeout
#     that leaves the controller invisible to BlueZ)
#   - make sure bluetooth.service is enabled and running
# Idempotent — safe to re-run.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[bluetooth] $*"; }

log "deploying btusb no-autosuspend drop-in..."
install -Dm644 "$SCRIPT_DIR/../configs/bluetooth/btusb-no-autosuspend.conf" \
  /etc/modprobe.d/btusb-no-autosuspend.conf

# Try to apply without a reboot: only when btusb is loaded, still on the
# old setting, and no controller is currently up (so we don't yank a live
# connection). A reload re-probes the USB interface and re-downloads the
# firmware, which also clears a stuck "-110" init.
if [ -d /sys/module/btusb ] &&
   [ "$(cat /sys/module/btusb/parameters/enable_autosuspend 2>/dev/null)" = "Y" ]; then
  if ! bluetoothctl list 2>/dev/null | grep -q .; then
    log "reloading btusb with enable_autosuspend=0..."
    if modprobe -r btusb 2>/dev/null && modprobe btusb 2>/dev/null; then
      sleep 2
      bluetoothctl list 2>/dev/null | grep -q . \
        && log "controller registered: $(bluetoothctl list 2>/dev/null)" \
        || log "still no controller — a full cold power-off may be needed"
    else
      log "btusb reload failed (in use?) — new setting takes effect on next boot"
    fi
  else
    log "controller already active; new setting applies on next boot"
  fi
fi

log "enabling bluetooth.service..."
systemctl enable --now bluetooth.service

log "done — check with: bluetoothctl show"
