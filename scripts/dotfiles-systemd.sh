#!/usr/bin/env bash
# Systemd user service configuration
# Enables and starts essential systemd user services

set -euo pipefail

HOME_DIR="${HOME}"
SYSTEMD_USER_DIR="$HOME_DIR/.config/systemd/user"

log() {
    echo "[dotfiles-systemd] $*"
}

# Check if systemd user directory exists
if [ ! -d "$SYSTEMD_USER_DIR" ]; then
    log "No systemd user services found, skipping"
    exit 0
fi

log "Configuring systemd user services..."

# Reload systemd user daemon to recognize new/updated unit files
systemctl --user daemon-reload

# Essential services to auto-enable
ESSENTIAL_SERVICES=(
    "darkman.service"
    "1password.service"
    "wallpaper.service"
)

# Enable and start essential services
for service in "${ESSENTIAL_SERVICES[@]}"; do
    if [ -f "$SYSTEMD_USER_DIR/$service" ]; then
        log "Enabling and starting $service"
        systemctl --user enable "$service" || log "Failed to enable $service (may not be available)"
        systemctl --user start "$service" || log "Failed to start $service (may not be available)"
    fi
done

log "Systemd user services configured"

# Print summary of available services
log "Available user services:"
systemctl --user list-unit-files --type=service --state=generated,static,enabled,disabled 2>/dev/null | grep -E "\.service.*enabled|disabled" | head -20 || true
