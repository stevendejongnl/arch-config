# Secrets Management

This document explains how to securely manage sensitive information (SSH keys, API tokens, credentials) in arch-config using git-crypt.

## Overview

**Secrets** are sensitive files that should never be committed unencrypted to version control:
- SSH private keys (`~/.ssh/id_rsa`)
- API tokens (GitLab, GitHub, etc.)
- Application credentials (`.auth_tokens`, `.bashrc.local` with passwords)
- Configuration with sensitive data

### The Problem

If you commit these to git:
- ❌ Anyone with repo access sees your private keys
- ❌ They appear in git history forever
- ❌ Compromised on any remote server that has the repo
- ❌ Accidental public repo exposure is catastrophic

### The Solution: git-crypt

**git-crypt** provides transparent encryption:
- ✅ Files encrypted in git repository
- ✅ Automatically decrypted when you work locally
- ✅ Access controlled by GPG keys (only authorized users can unlock)
- ✅ Works with git history/merge/diff normally
- ✅ No workflow changes needed

## How git-crypt Works

```
┌─────────────────────────────────────────────────────────┐
│  Your Working Directory                                 │
│  ~/.ssh/id_rsa (plaintext, readable)                    │
└─────────────────────────────────────────────────────────┘
           ↓ git add/commit (encrypted automatically)
┌─────────────────────────────────────────────────────────┐
│  Git Repository (.git/)                                 │
│  secrets/ssh/id_rsa (encrypted with AES-256)            │
│  Only readable to those with GPG key                    │
└─────────────────────────────────────────────────────────┘
           ↓ git-crypt unlock (decrypts with GPG)
┌─────────────────────────────────────────────────────────┐
│  Local Working Directory (another machine)              │
│  ~/.ssh/id_rsa (plaintext, readable)                    │
│  Only possible with authorized GPG key                  │
└─────────────────────────────────────────────────────────┘
```

## Directory Structure

```
~/.config/arch-config/secrets/
├── .gitattributes          # git-crypt encryption filters
├── ssh/
│   ├── id_rsa              # ENCRYPTED: SSH private key
│   ├── id_rsa.pub          # NOT encrypted: SSH public key (shareable)
│   ├── config              # ENCRYPTED: SSH host configurations
│   └── authorized_keys     # NOT encrypted: Public keys (if server)
└── credentials/
    ├── auth_tokens         # ENCRYPTED: Application tokens
    ├── gitlab_token        # ENCRYPTED: GitLab token (if separate)
    └── github_token        # ENCRYPTED: GitHub token (if separate)
```

## Setup

### Initial Setup (First Time)

This is done once per repository:

```bash
cd ~/.config/arch-config

# 1. Install git-crypt (if not already installed)
sudo pacman -S git-crypt

# 2. Initialize git-crypt in the repo
git-crypt init

# 3. Create secrets directory structure
mkdir -p secrets/ssh
mkdir -p secrets/credentials

# 4. Create .gitattributes to mark files for encryption
cat > secrets/.gitattributes <<'EOF'
# SSH keys (encrypted)
ssh/id_rsa filter=git-crypt diff=git-crypt
ssh/config filter=git-crypt diff=git-crypt
ssh/authorized_keys filter=git-crypt diff=git-crypt

# Credentials (encrypted)
credentials/** filter=git-crypt diff=git-crypt
EOF

# 5. Commit .gitattributes
git add secrets/.gitattributes
git commit -m "Initialize git-crypt structure"

# 6. Add your GPG key for encryption
git-crypt add-gpg-user YOUR_GPG_KEY_ID

# 7. Verify GPG key was added
git-crypt status

# At this point, git-crypt is initialized and your GPG key controls access
```

### Populating Secrets

After setup, move secrets into the repository:

```bash
cd ~/.config/arch-config

# Copy SSH keys
cp ~/.ssh/id_rsa secrets/ssh/
cp ~/.ssh/id_rsa.pub secrets/ssh/
cp ~/.ssh/config secrets/ssh/ 2>/dev/null || echo "No SSH config"

# Copy credentials
cp ~/.auth_tokens secrets/credentials/ 2>/dev/null || true

# View what will be encrypted
git-crypt status

# Commit encrypted secrets
git add secrets/
git commit -m "Add encrypted SSH keys and credentials"

# Verify files are encrypted in git
git show HEAD:secrets/ssh/id_rsa | head -20
# Output should look like random binary data, not key content
```

### Granting Access to Other Users

To allow another user to decrypt secrets:

```bash
# Get their GPG key ID (they should provide this)
# Option A: They send you their key
gpg --import ~/Downloads/their-public-key.asc

# Option B: Import from keyserver
gpg --recv-keys THEIR_KEY_ID

# Add their GPG key to git-crypt
git-crypt add-gpg-user THEIR_KEY_ID

# Verify
git-crypt status | grep "keys: "

# Commit the change
git add .git-crypt/
git commit -m "Add THEIR_NAME to git-crypt access"

# Push to remote
git push
```

## Working with Encrypted Secrets

### Unlocking Secrets on New Machine

When cloning on a new machine:

```bash
cd ~/.config/arch-config

# Install git-crypt
sudo pacman -S git-crypt

# Ensure your GPG key is imported
gpg --list-secret-keys

# Unlock the repository
git-crypt unlock
# Your GPG passphrase will be prompted

# Verify unlock
git-crypt status | grep -c "encrypted"
# Should output: 0 (no encrypted files visible)

# Deploy secrets to home directory
bash scripts/secrets-decrypt.sh
```

### Deploying Secrets

The `scripts/secrets-decrypt.sh` script handles deployment:

```bash
# Manual deployment (if needed)
bash scripts/secrets-decrypt.sh

# Or as part of dcli sync
dcli sync

# Verify deployment
ls -la ~/.ssh/id_rsa      # Should exist with 600 permissions
ls -la ~/.auth_tokens      # Should exist with 600 permissions
```

### Verifying Encryption

Verify files are properly encrypted in git:

```bash
# Check encryption status
git-crypt status

# Expected output:
#     encrypted: secrets/ssh/id_rsa
#     encrypted: secrets/ssh/config
#     encrypted: secrets/credentials/auth_tokens
#   unencrypted: secrets/ssh/id_rsa.pub

# View encrypted file in git (should be binary/unreadable)
git show HEAD:secrets/ssh/id_rsa | file -
# Output should indicate binary data
```

## Common Tasks

### Adding a New Secret

When you have a new secret to protect:

```bash
# 1. Copy to secrets directory
cp ~/new-secret secrets/credentials/

# 2. Verify it will be encrypted
# Check that it matches a pattern in secrets/.gitattributes
cat secrets/.gitattributes

# 3. Add to git
git add secrets/credentials/new-secret

# 4. Verify encryption
git-crypt status | grep new-secret
# Should show "encrypted"

# 5. Commit
git commit -m "Add new secret: new-secret"

# 6. Deploy to home directory
bash scripts/secrets-decrypt.sh
```

### Rotating SSH Keys

When you need to update SSH keys:

```bash
# 1. Generate new SSH key (on your machine)
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_new

# 2. Replace in secrets
cp ~/.ssh/id_rsa_new ~/.config/arch-config/secrets/ssh/id_rsa
cp ~/.ssh/id_rsa_new.pub ~/.config/arch-config/secrets/ssh/id_rsa.pub

# 3. Commit new keys
git add secrets/ssh/id_rsa*
git commit -m "Rotate SSH keys"

# 4. Update servers with new public key
# For each server that uses this key:
ssh-copy-id -i ~/.ssh/id_rsa.pub user@server

# 5. On other machines, pull and unlock
git pull
git-crypt unlock
bash scripts/secrets-decrypt.sh

# 6. Verify new key works
ssh -T git@github.com
```

### Updating Credentials

When credentials change:

```bash
# 1. Update locally
vim ~/.auth_tokens

# 2. Copy to secrets
cp ~/.auth_tokens ~/.config/arch-config/secrets/credentials/

# 3. Commit
git add secrets/credentials/auth_tokens
git commit -m "Update authentication tokens"

# 4. Push to remote
git push

# 5. Deploy on other machines
git pull
bash scripts/secrets-decrypt.sh
```

### Viewing History of Encrypted Files

git-crypt allows you to view history normally:

```bash
# View commits affecting secrets
git log --follow -p secrets/ssh/id_rsa

# View who changed what
git blame secrets/credentials/auth_tokens

# See all changes to secrets
git log --name-status secrets/

# These commands work normally - git-crypt doesn't hide history
```

### Exporting Secrets for Backup

Backup your encrypted secrets securely:

```bash
# Option 1: Backup entire secrets directory (encrypted in git)
tar -czf ~/secrets-backup.tar.gz ~/.config/arch-config/secrets/

# Option 2: Export plaintext backup (store securely!)
# Create plaintext backup of all secrets
mkdir ~/secrets-plaintext-backup
cp -r ~/.config/arch-config/secrets/* ~/secrets-plaintext-backup/

# Encrypt this backup with GPG
tar -czf - ~/secrets-plaintext-backup | \
  gpg --symmetric --cipher-algo AES256 > ~/secrets-plaintext-backup.tar.gz.gpg

# Delete plaintext backup
rm -rf ~/secrets-plaintext-backup

# Store in password manager or secure location
```

## Security Best Practices

### 1. GPG Key Management

```bash
# Backup your GPG key securely
gpg --export-secret-keys YOUR_KEY_ID > ~/gpg-private-key.asc

# Store backup in:
# - Password manager (1Password, Bitwarden, etc.)
# - Offline USB (encrypted)
# - Hardware security key backup location

# Never commit GPG keys to git!
```

### 2. SSH Key Permissions

```bash
# Verify SSH key permissions are correct
ls -la ~/.ssh/id_rsa
# Must show: -rw------- (600)

# If permissions are wrong, fix them
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh
```

### 3. Credential Rotation Schedule

- **SSH Keys**: Rotate every 1-2 years, or after suspected compromise
- **API Tokens**: Rotate every 3-6 months
- **Passwords**: Rotate when changing platforms or after breaches

### 4. Access Control

```bash
# Only add GPG keys of people who NEED access
# Fewer people = lower risk

# Remove access if someone leaves
git log --all --grep="git-crypt add-gpg-user"

# Create new key if someone's key is compromised
git-crypt add-gpg-user BACKUP_KEY_ID
# Make new key the primary
```

### 5. Repository Access

- Use SSH (not HTTPS) for git operations
- Enable 2FA on GitHub/GitLab
- Restrict repository access to team members only
- Use deploy keys for CI/CD (avoid storing in environment variables)

## Troubleshooting

### Problem: git-crypt unlock fails

```bash
# Cause: GPG key not available or not trusted

# Solution 1: Import GPG key
gpg --import ~/gpg-private-key.asc

# Solution 2: Trust the key
gpg --edit-key YOUR_KEY_ID
# At prompt: trust
# Select: 5 (I trust ultimately)
# Confirm: y

# Solution 3: Check GPG agent
gpg-agent --daemon  # Start GPG agent if needed

# Try unlock again
git-crypt unlock
```

### Problem: Can't view encrypted file in editor

```bash
# Files are encrypted until git-crypt unlocks them

# Solution: Unlock first
git-crypt unlock

# Verify unlock
git-crypt status | grep encrypted
# Should show no encrypted files

# Now view the file
cat ~/.config/arch-config/secrets/ssh/id_rsa
# Should show actual key content
```

### Problem: Changes not syncing to other machines

```bash
# Cause: New secrets not committed or pushed

# Solution:
git add secrets/
git status secrets/

# If encrypted files show as modified:
git add -f secrets/file-name  # Force add

# Commit
git commit -m "Update secrets"

# Push to remote
git push

# On other machine:
git pull
git-crypt unlock
bash scripts/secrets-decrypt.sh
```

### Problem: "git-crypt: encrypted key could not be decrypted"

```bash
# Cause: GPG key can't decrypt git-crypt key

# Solution 1: Check passphrase
git-crypt unlock
# You'll be prompted for GPG passphrase

# Solution 2: Verify GPG key is correct
gpg --list-secret-keys
# Find your key ID

# Solution 3: Ask repo administrator to re-add your key
git-crypt add-gpg-user YOUR_KEY_ID

# They commit and push
# You pull and unlock
```

## Integration with Other Tools

### With SSH Agent

```bash
# Store SSH passphrase in SSH agent (optional)
ssh-add ~/.ssh/id_rsa
# You'll be prompted for passphrase once

# SSH operations now use cached key
git clone git@github.com:username/repo.git
```

### With Git Hooks

```bash
# Create pre-commit hook to prevent unencrypted commits
cat > ~/.config/arch-config/.git/hooks/pre-commit <<'EOF'
#!/bin/bash
git-crypt status | grep -q "encrypted: secrets/" || {
    echo "ERROR: Secrets not encrypted before commit!"
    exit 1
}
EOF

chmod +x ~/.config/arch-config/.git/hooks/pre-commit
```

### With 1Password CLI

```bash
# If using 1Password to store secrets
op item get "SSH Key" --field label=private-key > \
  ~/.config/arch-config/secrets/ssh/id_rsa

git add secrets/ssh/id_rsa
git commit -m "Update SSH key from 1Password"
```

## Related Documentation

- [Bootstrap Guide](../bootstrap/README.md) - Setting up on new machine
- [Dotfiles Management](./DOTFILES.md) - Managing configuration files
- [git-crypt Documentation](https://github.com/AGWA/git-crypt) - Official docs
- [CLAUDE.md](../CLAUDE.md) - Project overview
