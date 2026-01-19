#!/usr/bin/env bash
# Secrets management script
# Unlocks git-crypt encrypted secrets and deploys them to home directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$REPO_ROOT/secrets"

log() {
    echo "[secrets-decrypt] $*"
}

error() {
    echo "[secrets-decrypt] ERROR: $*" >&2
    exit 1
}

# Check if secrets directory exists
if [ ! -d "$SECRETS_DIR" ]; then
    log "No secrets directory found, skipping"
    exit 0
fi

cd "$REPO_ROOT"

# Check if git-crypt is installed
if ! command -v git-crypt &> /dev/null; then
    error "git-crypt not installed. Install it with: sudo pacman -S git-crypt"
fi

# Check if there are encrypted files to unlock
if git-crypt status 2>/dev/null | grep -q "encrypted"; then
    log "Unlocking git-crypt encrypted secrets..."

    if ! git-crypt unlock 2>/dev/null; then
        error "Failed to unlock secrets. Ensure your GPG key is available and trusted."
    fi

    log "Secrets unlocked successfully"
else
    log "Secrets already unlocked or no encrypted files found"
fi

log "Deploying secrets..."

# Deploy SSH keys
if [ -d "$SECRETS_DIR/ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    log "Deploying SSH keys..."
    rsync -a --ignore-errors "$SECRETS_DIR/ssh/" "$HOME/.ssh/" || log "Warning: Some SSH files failed to copy"

    # Set correct permissions for private keys
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        chmod 600 "$HOME/.ssh/id_rsa"
        log "SSH private key permissions set to 600"
    fi

    if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        chmod 644 "$HOME/.ssh/id_rsa.pub"
        log "SSH public key permissions set to 644"
    fi

    if [ -f "$HOME/.ssh/config" ]; then
        chmod 600 "$HOME/.ssh/config"
        log "SSH config permissions set to 600"
    fi

    log "SSH keys deployed successfully"
fi

# Deploy application credentials
if [ -d "$SECRETS_DIR/credentials" ]; then
    log "Deploying application credentials..."

    if [ -f "$SECRETS_DIR/credentials/auth_tokens" ]; then
        rsync -a "$SECRETS_DIR/credentials/auth_tokens" "$HOME/.auth_tokens" || log "Warning: auth_tokens failed to copy"
        chmod 600 "$HOME/.auth_tokens" 2>/dev/null || true
        log "Auth tokens deployed"
    fi

    if [ -f "$SECRETS_DIR/credentials/gitlab_token" ]; then
        rsync -a "$SECRETS_DIR/credentials/gitlab_token" "$HOME/.gitlab_token" || log "Warning: gitlab_token failed to copy"
        chmod 600 "$HOME/.gitlab_token" 2>/dev/null || true
        log "GitLab token deployed"
    fi
fi

log "Secrets deployment complete"

# Verify SSH key is accessible
if [ -f "$HOME/.ssh/id_rsa" ]; then
    log "Verifying SSH key accessibility..."
    if ssh -T git@github.com 2>&1 | grep -q "authentication"; then
        log "SSH authentication working"
    else
        log "Warning: SSH authentication may need verification"
    fi
fi
