# Bootstrap Process for New Arch Linux Machine

This guide walks through setting up a fresh Arch Linux installation to match your current system configuration using arch-config, dcli, and encrypted secrets management.

## Overview

The bootstrap process will:
1. Install core tools (git, GPG, base-devel)
2. Decrypt SSH keys for secure git operations
3. Install all system packages (115+)
4. Deploy dotfiles from arch-config
5. Configure systemd user services
6. Deploy application credentials

**Result**: A fully configured Arch Linux system identical to computersloeber, ready to use.

## Prerequisites

- **Fresh Arch Linux installation** with internet connection and sudo access
- **Your GPG private key** (needed to decrypt secrets)
  - If you don't have it, recover from: password manager, secure backup location, or GPG keyserver
  - Command: `gpg --recv-keys <YOUR_GPG_KEY_ID>`

## Step-by-Step Bootstrap

### Step 1: Install Basic Tools

After fresh Arch install, open a terminal and install essential tools:

```bash
sudo pacman -S --noconfirm git base-devel gnupg
```

What this installs:
- `git` - Version control (needed to clone arch-config)
- `base-devel` - Build essentials (needed for AUR packages)
- `gnupg` - GPG encryption tools (needed to decrypt secrets)

### Step 2: Import Your GPG Key

Before cloning arch-config, your GPG key must be available locally:

**Option A: Import from file** (if you have a key backup)
```bash
gpg --import /path/to/private-key.asc
# Enter your GPG passphrase when prompted
```

**Option B: Sync with GPG keyserver** (if previously backed up)
```bash
gpg --recv-keys YOUR_GPG_KEY_ID
# Example: gpg --recv-keys 4B1A3D7E
```

**Option C: Import from password manager**
```bash
# Export key from password manager, save to file, then import:
gpg --import ~/Downloads/private-key.asc
```

Verify GPG key is available:
```bash
gpg --list-secret-keys
# You should see your key in the output
```

### Step 3: Clone arch-config Repository

```bash
git clone git@github.com:stevendejongnl/arch-config.git ~/.config/arch-config
cd ~/.config/arch-config

# Verify it's a git repository
git status
```

**If SSH key not available yet**: Use HTTPS temporarily
```bash
git clone https://github.com/stevendejongnl/arch-config.git ~/.config/arch-config
cd ~/.config/arch-config
```

### Step 4: Unlock Encrypted Secrets

This step decrypts SSH keys and credentials using git-crypt:

```bash
cd ~/.config/arch-config

# Install git-crypt (if not already installed)
sudo pacman -S --noconfirm git-crypt

# Unlock secrets
git-crypt unlock
# Your GPG passphrase will be prompted

# Verify unlock successful
git-crypt status | grep "encrypted"
# Output should be empty (everything is decrypted)
```

### Step 5: Deploy SSH Keys (for secure git operations)

This makes SSH keys available for subsequent git operations:

```bash
cd ~/.config/arch-config
bash scripts/secrets-decrypt.sh
```

Verify SSH key is deployed:
```bash
ls -la ~/.ssh/id_rsa
# Should show: -rw------- (600 permissions)

# Test SSH connection
ssh -T git@github.com
# Should show: "Hi USERNAME! You've successfully authenticated..."
```

### Step 6: Install dcli and Dependencies

Install dcli and its required dependencies:

```bash
# Install dependencies
sudo pacman -S --noconfirm yay fzf timeshift stow rsync

# Install dcli (from AUR via yay)
yay -S --noconfirm dcli

# Verify installation
dcli --version
```

### Step 7: Configure dcli Active Host

Tell dcli which host configuration to use (computersloeber):

```bash
cd ~/.config/arch-config
cat config.yaml  # Verify host is set to 'computersloeber'

# If not set, update config.yaml:
# host: computersloeber
```

### Step 8: Preview Changes with Dry-Run

Before making changes, preview what dcli will do:

```bash
cd ~/.config/arch-config
dcli sync --dry-run

# Review the output:
# - Packages to install
# - Dotfiles to deploy
# - Services to enable
```

**If anything looks wrong**: Abort and review configuration before proceeding.

### Step 9: Apply System Configuration

This is the main installation step - packages will be installed and system configured:

```bash
cd ~/.config/arch-config
dcli sync

# This will:
# 1. Install all 115+ packages (may take 10-30 minutes)
# 2. Execute scripts/ hooks (dwm.sh, dotfiles-deploy.sh, etc.)
# 3. Deploy dotfiles via stow
# 4. Enable systemd user services
# 5. Create backups via timeshift
```

**Monitor the output** for any errors. Common issues:

| Issue | Solution |
|-------|----------|
| `pacman: command not found` | Wait for pacman to finish updating |
| `git-crypt: command not found` | Rerun `sudo pacman -S git-crypt` |
| `stow: command not found` | Rerun `sudo pacman -S stow` |
| `permission denied` on /root | Run dcli with sudo (dcli respects file ownership) |

### Step 10: Verify System Setup

After dcli completes, verify everything is configured correctly:

**Check dotfiles are symlinked:**
```bash
ls -la ~/.zshrc
# Should show: .zshrc -> ../.config/arch-config/dotfiles/.zshrc
```

**Check SSH permissions:**
```bash
ls -la ~/.ssh/
# id_rsa should be 600 (rw-------)
# id_rsa.pub should be 644 (rw-r--r--)
```

**Check systemd services:**
```bash
systemctl --user status darkman.service
systemctl --user status 1password.service
# Should show: active (running)
```

**Check DWM configuration:**
```bash
ls -la ~/.dwm/
# Should show symlinks to DWM statusbar and autostart scripts
```

**Look for broken symlinks:**
```bash
find ~ -maxdepth 3 -xtype l 2>/dev/null
# Should return nothing (no broken links)
```

### Step 11: Start Display Server

Once everything is verified, start your X11 session with DWM:

```bash
startx

# DWM should start with your custom configuration
# Mod+Shift+Q to quit DWM and return to terminal
```

### Step 12: Final System Verification

Once in DWM, verify applications work:

- [ ] Open terminal: `Mod+Shift+Return` (alacritty should start)
- [ ] Launch rofi: `Mod+D` (application launcher should work)
- [ ] Check wallpaper (darkman/autorandr should apply settings)
- [ ] Verify systemd services: `systemctl --user status` (no failed services)
- [ ] Test git: `git clone <test-repo>` (SSH keys should work)

## Troubleshooting

### Problem: git-crypt unlock fails with "No GPG key found"

**Solution:**
```bash
# Check if GPG key is properly imported
gpg --list-secret-keys

# If key is missing, import it:
gpg --import /path/to/private-key.asc

# Try unlock again
git-crypt unlock
```

### Problem: "stow error: existing target is not a symlink"

**Cause**: Conflicting files exist in home directory

**Solution:**
```bash
# Move conflicting files
mkdir ~/.backup-conflicts
mv ~/.zshrc ~/.backup-conflicts/

# Rerun dcli
dcli sync
```

### Problem: SSH key authentication fails

**Cause**: SSH key permissions are wrong

**Solution:**
```bash
# Fix permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh

# Test SSH
ssh -T git@github.com
```

### Problem: Systemd services fail to start

**Cause**: Service files not properly deployed

**Solution:**
```bash
# Reload systemd user daemon
systemctl --user daemon-reload

# Check service status
systemctl --user status darkman.service

# View logs
journalctl --user -u darkman.service -n 20
```

### Problem: DWM fails to start with startx

**Cause**: X11 configuration or xmodmap issue

**Solution:**
```bash
# Check xinitrc is properly configured
cat ~/.xinitrc

# Manually start X with debugging
startx -- -verbose 2 > /tmp/x11.log

# Check logs
cat /tmp/x11.log
```

## Rollback to Previous State

If something goes wrong and you need to undo changes:

### Restore from Timeshift Backup

```bash
# List available backups
sudo timeshift --list

# Restore to previous backup
sudo timeshift --restore --snapshot=<snapshot_name>

# Reboot system
sudo reboot
```

### Manual Rollback

Remove stow symlinks:
```bash
cd ~/.config/arch-config/dotfiles
stow --delete --target="$HOME" .
```

Restore from backup:
```bash
# If you backed up before bootstrap
cp -r ~/arch-config-backup/* ~/.config/arch-config/
```

## Next Steps After Bootstrap

1. **Customize DWM**: Edit `~/.dwm/dwm/config.h` and rebuild with `dwm.sh`
2. **Update SSH config**: Edit `~/.ssh/config` with your hosts
3. **Configure Git**: Run `git config --global user.name "Your Name"`
4. **Install additional tools**: `yay -S <package-name>`
5. **Configure systemd services**: Edit `~/.config/systemd/user/*.service`

## Need Help?

- Check CLAUDE.md for project documentation
- Review docs/DOTFILES.md for dotfiles management
- Review docs/SECRETS.md for secrets management
- Check dcli documentation: `dcli --help`
- View system logs: `journalctl -n 50`

## Testing on Another Machine

Once bootstrap works on one machine, test on another to verify portability:

1. Provision fresh Arch VM or physical machine
2. Follow entire bootstrap process (Steps 1-12)
3. Document any differences or issues
4. Update this README if needed

This confirms arch-config works across different hardware setups.

---

**Bootstrap complete!** Your system should now match your arch-config configuration. Enjoy your reproducible Arch Linux setup!
