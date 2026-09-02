#!/usr/bin/env bash
# Enable TLP so laptop battery/CPU power draw is actually managed.
# (tlp.service is a system service, no user-session dance needed here.)
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[power-management] deploying charge threshold config..."
install -Dm644 "$SCRIPT_DIR/../configs/tlp/10-battery-thresholds.conf" \
  /etc/tlp.d/10-battery-thresholds.conf

echo "[power-management] enabling tlp.service..."
systemctl enable --now tlp.service
systemctl restart tlp.service

if systemctl is-enabled power-profiles-daemon.service &>/dev/null; then
  echo "[power-management] disabling power-profiles-daemon (conflicts with tlp)..."
  systemctl disable --now power-profiles-daemon.service
fi

echo "[power-management] done — check status with: tlp-stat -s"
