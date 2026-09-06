#!/usr/bin/env bash
# Make NetworkManager the active network stack.
# archinstall commonly provisions systemd-networkd (+ iwd for wifi auth);
# this hook hands networking to NetworkManager and keeps iwd only as NM's
# wifi backend. Idempotent — safe to re-run.
set -u

log() { echo "[networkmanager] $*"; }

# iwd, if present, stays as NM's wifi backend (better than wpa_supplicant on
# modern hardware, and preserves any already-saved networks).
if pacman -Qq iwd >/dev/null 2>&1; then
  install -d -m755 /etc/NetworkManager/conf.d
  printf '[device]\nwifi.backend=iwd\n' > /etc/NetworkManager/conf.d/wifi_backend.conf
  log "wifi.backend=iwd"
  systemctl enable --now iwd.service 2>/dev/null || true
fi

# Tear down systemd-networkd — NM owns IP/DHCP now.
for u in systemd-networkd.service systemd-networkd.socket \
         systemd-networkd-wait-online.service systemd-network-generator.service \
         systemd-networkd-varlink.socket systemd-networkd-varlink-metrics.socket \
         systemd-networkd-resolve-hook.socket; do
  systemctl disable --now "$u" 2>/dev/null || true
done
if ls /etc/systemd/network/*.network >/dev/null 2>&1; then
  mkdir -p /etc/systemd/network/disabled~
  mv /etc/systemd/network/*.network /etc/systemd/network/disabled~/ 2>/dev/null || true
  log "parked /etc/systemd/network/*.network"
fi

# systemd-resolved stays — NM integrates with it for DNS.

log "enabling NetworkManager.service"
systemctl enable --now NetworkManager.service
systemctl enable NetworkManager-wait-online.service 2>/dev/null || true

# Give NM a moment, then report.
for _ in $(seq 1 15); do
  nmcli -t -f STATE g 2>/dev/null | grep -q connected && break
  sleep 1
done
log "state: $(nmcli -t -f STATE,CONNECTIVITY g 2>/dev/null)"
log "done — 'nmtui' or 'nmcli device wifi connect <SSID>' if a network needs adding"
