#!/usr/bin/env bash
# Deploy the reflector config, refresh the mirrorlist once now, and enable the
# weekly refresh timer.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[mirrors] deploying reflector config..."
install -Dm644 "$SCRIPT_DIR/../configs/reflector/reflector.conf" \
  /etc/xdg/reflector/reflector.conf

echo "[mirrors] refreshing the mirrorlist now..."
systemctl start reflector.service

echo "[mirrors] enabling reflector.timer..."
systemctl enable --now reflector.timer

echo "[mirrors] done — check with: systemctl list-timers reflector.timer"
