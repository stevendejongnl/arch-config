#!/usr/bin/env bash
# Dotfiles deployment script using GNU stow
# Symlinks dotfiles from arch-config/dotfiles to home directory
# Safe to run multiple times (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_ROOT/dotfiles"
HOME_DIR="${HOME}"

log() {
    echo "[dotfiles-deploy] $*"
}

error() {
    echo "[dotfiles-deploy] ERROR: $*" >&2
    exit 1
}

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    log "Dotfiles directory not found at $DOTFILES_DIR, skipping"
    exit 0
fi

log "Starting dotfiles deployment..."

# Backup existing dotfiles if they're not symlinks
backup_if_exists() {
    local file="$1"
    if [ -e "$HOME_DIR/$file" ] && [ ! -L "$HOME_DIR/$file" ]; then
        local backup_dir="$HOME_DIR/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        log "Backing up existing $file to $backup_dir"
        rsync -a --relative "$HOME_DIR/$file" "$backup_dir/"
    fi
}

# Critical dotfiles to backup before deployment
CRITICAL_FILES=(
    ".config/X11"
    ".config/picom"
    ".config/rofi"
    ".config/nvim"
    ".config/alacritty"
    ".config/tmux"
    ".config/autorandr"
    ".config/darkman"
    ".dwm"
    ".zshrc"
    ".bashrc"
    ".bash_profile"
    ".aliases"
    ".gitconfig"
    ".local/bin"
    ".local/share/applications"
)

log "Backing up existing dotfiles..."
for file in "${CRITICAL_FILES[@]}"; do
    backup_if_exists "$file"
done

# Deploy with stow
log "Deploying dotfiles with GNU stow..."
cd "$DOTFILES_DIR"

# Use stow with --restow to intelligently symlink
# --restow: Restow (unstow then stow) to fix any conflicts
# --verbose=1: Show what's being done
# --target: Where to create symlinks (home directory)
# . : Everything in current directory
if ! stow --verbose=1 --target="$HOME_DIR" --restow .; then
    error "Stow failed. Check for conflicts with existing files."
fi

log "Dotfiles deployed successfully"

# Run systemd service configuration if available
if [ -f "$REPO_ROOT/scripts/dotfiles-systemd.sh" ]; then
    log "Configuring systemd user services..."
    bash "$REPO_ROOT/scripts/dotfiles-systemd.sh"
fi

log "Dotfiles deployment complete"
