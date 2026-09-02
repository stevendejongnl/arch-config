#!/usr/bin/env bash
# Enable TLP so laptop battery/CPU power draw is actually managed.
# (tlp.service is a system service, no user-session dance needed here.)
set -u

echo "[power-management] enabling tlp.service..."
systemctl enable --now tlp.service

if systemctl is-enabled power-profiles-daemon.service &>/dev/null; then
  echo "[power-management] disabling power-profiles-daemon (conflicts with tlp)..."
  systemctl disable --now power-profiles-daemon.service
fi

echo "[power-management] done — check status with: tlp-stat -s"
