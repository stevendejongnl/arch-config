#!/usr/bin/env bash
# Keyboard backlight restoration script
# Restores keyboard backlight to configured brightness after suspend/resume

set -euo pipefail

# Configuration
KBD_DEVICE="tpacpi::kbd_backlight"
DESIRED_BRIGHTNESS=2  # 0=off, 1=dim, 2=bright

# Verify brightnessctl is installed
if ! command -v brightnessctl &> /dev/null; then
    echo "[kbd-backlight-restore] ERROR: brightnessctl not found" >&2
    exit 1
fi

# Verify keyboard backlight device exists
if ! brightnessctl --list 2>/dev/null | grep -q "$KBD_DEVICE"; then
    echo "[kbd-backlight-restore] ERROR: Device '$KBD_DEVICE' not found" >&2
    exit 1
fi

# Get current brightness
CURRENT_BRIGHTNESS=$(brightnessctl --device="$KBD_DEVICE" get 2>/dev/null || echo "0")

# Restore brightness if needed
if [ "$CURRENT_BRIGHTNESS" != "$DESIRED_BRIGHTNESS" ]; then
    brightnessctl --device="$KBD_DEVICE" set "$DESIRED_BRIGHTNESS" &> /dev/null || {
        echo "[kbd-backlight-restore] ERROR: Failed to restore brightness" >&2
        exit 1
    }
fi
