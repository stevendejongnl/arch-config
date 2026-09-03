#!/usr/bin/env bash
# Clone/update the rime theme repo and install its components (alacritty,
# tmux, rofi, dunst, gtk, qt, chromium, vscodium, dark-mode, dwm scheme).
# Repo lives in ~/workspace/rime on all machines.
set -u

if [ "$(id -u)" -eq 0 ]; then
  HOME_DIR=$(eval echo "~$SUDO_USER")
else
  HOME_DIR="$HOME"
fi

run_as_user() {
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    sudo -u "$SUDO_USER" env \
      HOME="$HOME_DIR" \
      XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$SUDO_USER")/bus" \
      "$@"
  else
    "$@"
  fi
}

repo_url="https://git.madebysteven.nl/stevendejong/rime.git"
target_dir="$HOME_DIR/workspace/rime"

if [ -d "$target_dir/.git" ]; then
  echo "Updating $target_dir ..."
  run_as_user git -C "$target_dir" pull --ff-only origin main \
    || echo "  (pull failed — installing from the existing checkout)"
else
  echo "Cloning $repo_url -> $target_dir ..."
  run_as_user mkdir -p "$(dirname "$target_dir")"
  run_as_user git clone "$repo_url" "$target_dir" || {
    echo "Error: could not clone rime repo (network)."
    exit 1
  }
fi

echo "Installing rime theme (all components) ..."
run_as_user "$target_dir/rime" install --all
