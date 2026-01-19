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

# Clean up old symlinks that point to wrong location (e.g., ~/dotfiles instead of ~/.config/arch-config/dotfiles)
log "Cleaning up old symlinks pointing to ~/dotfiles..."
find "$HOME_DIR" -maxdepth 1 -type l 2>/dev/null | while read link; do
    target=$(readlink "$link" 2>/dev/null || true)
    # Remove if symlink target looks like old path: starts with "dotfiles/" (relative path)
    if [ -n "$target" ] && echo "$target" | grep -q "^dotfiles/"; then
        log "Removing old symlink: $(basename "$link") → $target"
        rm -f "$link"
    fi
done

# Also clean up .config symlinks with old relative paths
find "$HOME_DIR/.config" -maxdepth 2 -type l 2>/dev/null | while read link; do
    target=$(readlink "$link" 2>/dev/null || true)
    if [ -n "$target" ] && echo "$target" | grep -q "^\.\./dotfiles/"; then
        log "Removing old symlink: $(basename "$link") → $target"
        rm -f "$link"
    fi
done

# Deploy with stow
log "Deploying dotfiles with GNU stow..."
cd "$DOTFILES_DIR"

# Use stow with --verbose to show what's being done
# --target: Where to create symlinks (home directory)
# . : Everything in current directory
if ! stow --verbose=1 --target="$HOME_DIR" .; then
    error "Stow failed. Check for conflicts with existing files."
fi

log "Dotfiles deployed successfully"

# Run systemd service configuration if available
if [ -f "$REPO_ROOT/scripts/dotfiles-systemd.sh" ]; then
    log "Configuring systemd user services..."
    bash "$REPO_ROOT/scripts/dotfiles-systemd.sh"
fi

log "Dotfiles deployment complete"
