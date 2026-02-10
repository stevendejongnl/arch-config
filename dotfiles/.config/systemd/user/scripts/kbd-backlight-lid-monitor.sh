#!/usr/bin/env bash
# Monitor lid state and restore keyboard backlight on lid open
# Runs as a systemd user service

set -euo pipefail

LID_STATE_FILE="/proc/acpi/button/lid/LID/state"
KBD_RESTORE_SCRIPT="/home/stevendejong/.config/systemd/user/scripts/kbd-backlight-restore.sh"
PREVIOUS_STATE="open"

echo "[kbd-backlight-lid-monitor] Starting lid state monitor..."

while true; do
    # Read current lid state
    if [ -f "$LID_STATE_FILE" ]; then
        CURRENT_STATE=$(awk '{print $2}' "$LID_STATE_FILE" 2>/dev/null || echo "unknown")

        # Detect lid open transition
        if [ "$PREVIOUS_STATE" = "closed" ] && [ "$CURRENT_STATE" = "open" ]; then
            echo "[kbd-backlight-lid-monitor] Lid opened - restoring backlight"
            bash "$KBD_RESTORE_SCRIPT" || true
        fi

        PREVIOUS_STATE="$CURRENT_STATE"
    fi

    # Check every second
    sleep 1
done
