#! /usr/bin/env bash

download_repo() {
  if [ "$(id -u)" -eq 0 ]; then
    HOME_DIR=$(eval echo "~$SUDO_USER")
  else
    HOME_DIR="$HOME"
  fi

  if [ ! -d "$HOME_DIR/builds" ]; then
    mkdir -p "$HOME_DIR/builds"
  fi

  repo_url="git@github.com:stevendejongnl/suckless.git"
  target_dir="$HOME_DIR/builds/suckless"

  if [ -d "$target_dir" ]; then
    echo "Repository already exists at $target_dir. Pulling latest changes..."
    cd "$target_dir" || exit
    git pull origin main
  else
    echo "Cloning repository from $repo_url to $target_dir..."
    git clone "$repo_url" "$target_dir"
  fi
}

install_dwm() {
  echo "Installing DWM..."
  make dwm
}

install_slstatus() {
  echo "Installing SLStatus..."
  make slstatus
}

download_repo
install_dwm
# install_slstatus
