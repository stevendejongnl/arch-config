#!/usr/bin/env bash
# Lock the desktop to dark mode and stop darkman from switching it back.
set -u

run_as_user() {
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    sudo -u "$SUDO_USER" env \
      XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$SUDO_USER")/bus" \
      "$@"
  else
    "$@"
  fi
}

echo "[dark-mode] disabling darkman scheduler..."
run_as_user systemctl --user disable --now darkman.service 2>/dev/null || true

echo "[dark-mode] setting persistent dark preferences..."
run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'            2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Dracula'                    2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Purple-Dracula-Dark' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface accent-color 'teal'                    2>/dev/null || true
run_as_user darkman set dark 2>/dev/null || true

echo "[dark-mode] done (env vars deploy via dotfiles ~/.config/environment.d/dark-mode.conf)"
