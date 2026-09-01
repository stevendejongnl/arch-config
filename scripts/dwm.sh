#! /usr/bin/env bash
# Build the suckless suite (dwm/dmenu/slock) from the personal fork.
# Repo lives in ~/workspace/builds/suckless on all machines.

set -u

download_repo() {
  if [ "$(id -u)" -eq 0 ]; then
    HOME_DIR=$(eval echo "~$SUDO_USER")
  else
    HOME_DIR="$HOME"
  fi

  repo_url="git@github.com:stevendejongnl/suckless.git"
  target_dir="$HOME_DIR/workspace/builds/suckless"

  if [ -d "$target_dir/.git" ]; then
    echo "Updating $target_dir ..."
    git -C "$target_dir" pull --ff-only origin main \
      || echo "  (pull failed — building from the existing checkout)"
  else
    echo "Cloning $repo_url -> $target_dir ..."
    mkdir -p "$(dirname "$target_dir")"
    git clone "$repo_url" "$target_dir" || {
      echo "Error: could not clone suckless repo (SSH auth / network)."
      exit 1
    }
  fi

  cd "$target_dir" || exit 1
}

install_dwm() {
  echo "Building dwm/dmenu/slock ..."
  make dwm
  make dmenu
  make slock
}

download_repo
install_dwm
