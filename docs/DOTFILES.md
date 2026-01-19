# Dotfiles Management

This document describes how dotfiles are managed in arch-config and how to work with them.

## Overview

**Dotfiles** are configuration files that define how applications behave and look. In arch-config, dotfiles are:

- **Stored in**: `~/.config/arch-config/dotfiles/`
- **Deployed to**: Home directory via GNU stow (creates symlinks)
- **Organized as**: Mirrored home directory structure
- **Version controlled**: Committed to git for reproducibility

### Why Symlinks?

Using GNU stow to create symlinks means:
- ✅ Single source of truth - edit in dotfiles/, changes apply immediately
- ✅ Version controlled - all changes tracked in git
- ✅ Easy rollback - just switch git branches
- ✅ No duplication - files exist once in arch-config

When you edit `~/.zshrc`, you're actually editing `~/.config/arch-config/dotfiles/.zshrc` (via symlink).

## Directory Structure

```
~/.config/arch-config/dotfiles/
├── .config/               # Application configs (XDG_CONFIG_HOME)
│   ├── X11/               # X11 configuration (xinitrc, Xresources)
│   ├── picom/             # Picom compositor config
│   ├── rofi/              # Rofi launcher config
│   ├── nvim/              # Neovim configuration
│   ├── alacritty/         # Alacritty terminal config
│   ├── tmux/              # Tmux multiplexer config
│   ├── autorandr/         # Display profile config
│   ├── darkman/           # Dark mode settings
│   ├── systemd/user/      # Systemd user services
│   ├── gtk-3.0/           # GTK theme/appearance
│   └── ...                # Other app configs
├── .dwm/                  # DWM window manager
│   ├── dwm/               # DWM source code and build
│   ├── statusbar.sh       # Status bar script
│   └── autostart.sh       # Startup script
├── .local/
│   ├── bin/               # Custom scripts and executables
│   └── share/applications/ # Desktop entry files
├── .zshrc                 # Zsh shell configuration
├── .bashrc                # Bash shell configuration
├── .bash_profile          # Bash profile (login shell)
├── .aliases               # Shared shell aliases
├── .gitconfig             # Git configuration
├── .gitignore_global      # Global git ignore rules
├── .stow-local-ignore     # Stow ignore patterns
└── ...                    # Other top-level dotfiles
```

## Managing Dotfiles

### Adding a New Dotfile

To add a new configuration file to version control:

```bash
# 1. Create directory structure in arch-config/dotfiles/
cd ~/.config/arch-config
mkdir -p dotfiles/.config/newapp

# 2. Copy or create the config file
cp ~/.config/newapp/config dotfiles/.config/newapp/

# 3. Remove the original (stow will symlink it)
rm ~/.config/newapp/config

# 4. Redeploy stow to create symlink
bash scripts/dotfiles-deploy.sh

# 5. Verify symlink was created
ls -la ~/.config/newapp/config
# Should show: config -> ../../.config/arch-config/dotfiles/.config/newapp/config

# 6. Test that the app still works
newapp --version

# 7. Commit to git
git add dotfiles/.config/newapp/
git commit -m "Add newapp configuration"
```

### Modifying Existing Dotfiles

Since dotfiles are symlinked, you can edit them directly:

```bash
# Edit through the symlink
vim ~/.zshrc

# Changes immediately apply (no deployment needed)
# Git sees changes in dotfiles/ directory
git status

# Commit changes
git add dotfiles/.zshrc
git commit -m "Update zsh config"
```

### Removing a Dotfile

To stop tracking a dotfile:

```bash
# 1. Back up the file (if needed)
cp ~/.config/app/config ~/.config/app/config.backup

# 2. Remove from arch-config
git rm dotfiles/.config/app/config

# 3. Redeploy stow to remove symlink
bash scripts/dotfiles-deploy.sh

# 4. Restore original or recreate manually
cp ~/.config/app/config.backup ~/.config/app/config

# 5. Commit removal
git commit -m "Remove app configuration from dotfiles"
```

### Excluding Files from Stow

Some files should NOT be symlinked. Configure `.stow-local-ignore`:

```yaml
# ~/.config/arch-config/dotfiles/.stow-local-ignore
# Patterns (regex) for files stow should ignore

# Ignore cache and runtime files
\.cache/
\.pid$
runtime/
\.state/

# Ignore temporary files
*~
\.tmp/
\.bak$

# Ignore machine-specific files
hostname
machine-id
```

After updating `.stow-local-ignore`, redeploy:
```bash
bash scripts/dotfiles-deploy.sh
```

## Deployment

### Manual Deployment

To deploy/redeploy all dotfiles:

```bash
cd ~/.config/arch-config

# Deploy (creates symlinks, backs up conflicts)
bash scripts/dotfiles-deploy.sh

# View what stow would do (dry-run)
cd dotfiles && stow --verbose=2 --target="$HOME" --dry-run . && cd ..
```

### Automatic Deployment via dcli

When running `dcli sync`:

```bash
dcli sync

# Internally runs:
# 1. Installs packages
# 2. Calls scripts/dotfiles-deploy.sh
# 3. Calls scripts/dotfiles-systemd.sh
```

### Conflict Resolution

If stow finds conflicting files:

```bash
# Error message shows conflicting file
# Stow creates backups in ~/.dotfiles-backup-TIMESTAMP/

# Review the backup
ls ~/.dotfiles-backup-*/

# Option A: Keep new dotfile
rm ~/.dotfiles-backup-TIMESTAMP/file
bash scripts/dotfiles-deploy.sh

# Option B: Keep old version
cp ~/.dotfiles-backup-TIMESTAMP/file ~/.
bash scripts/dotfiles-deploy.sh

# Option C: Merge both versions
diff -u ~/.dotfiles-backup-TIMESTAMP/file ~/.file
# Edit to merge, then redeploy
```

## Common Tasks

### Sync Dotfiles to Another Machine

```bash
# On new machine, run bootstrap
bash bootstrap/README.md  # See bootstrap guide

# After dcli sync, all dotfiles are deployed
```

### Update Dotfiles from Backup

If you accidentally deleted a dotfile:

```bash
# Check git history
git log --oneline dotfiles/.zshrc

# Restore from git
git checkout HEAD~3 dotfiles/.zshrc

# Redeploy
bash scripts/dotfiles-deploy.sh
```

### Create Machine-Specific Variations

For machine-specific configs:

```bash
# Option 1: Use separate branch
git checkout -b config/laptop
# Edit dotfiles for laptop
git commit -am "Customize for laptop"

# Option 2: Use conditional in dotfile
# In ~/.zshrc:
if [ "$HOSTNAME" = "laptop" ]; then
    # Laptop-specific settings
fi

# Option 3: Keep separate .local config files
# In ~/.zshrc:
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
# Add ~/.zshrc.local to .stow-local-ignore
```

### Backup Before Major Changes

```bash
# Create git commit of current state
git add -A
git commit -m "Backup before major dotfiles refactor"

# Create git tag
git tag backup-before-refactor

# Make changes
# If needed, reset to backup:
# git checkout backup-before-refactor
```

## Systemd User Services

User-level systemd services are managed through dotfiles:

```
~/.config/arch-config/dotfiles/.config/systemd/user/
├── darkman.service          # Dark mode switcher
├── 1password.service        # 1Password authentication
├── wallpaper.service        # Wallpaper manager
└── ...
```

### Enabling a Service

```bash
# Service file must exist in dotfiles/
ls ~/.config/systemd/user/myservice.service

# Enable service
systemctl --user enable myservice.service

# Start service
systemctl --user start myservice.service

# Check status
systemctl --user status myservice.service
```

### Viewing Service Logs

```bash
# View recent logs
journalctl --user -u myservice.service -n 20

# Follow logs in real-time
journalctl --user -u myservice.service -f

# View all user services
systemctl --user list-units --type=service
```

### Disabling a Service

```bash
# Stop service
systemctl --user stop myservice.service

# Disable (prevents auto-start)
systemctl --user disable myservice.service
```

## Troubleshooting

### Symlink Not Created

```bash
# Check if stow sees the file
cd dotfiles && stow --verbose=2 --target="$HOME" --dry-run . && cd ..

# Common causes:
# - File already exists and is not a symlink
# - Directory in between doesn't exist
# - File is in .stow-local-ignore

# Solution: Remove or rename the conflicting file
rm ~/.conflicting-file
bash scripts/dotfiles-deploy.sh
```

### "Too many levels of symbolic links"

**Cause**: Circular symlink

```bash
# Find circular symlinks
find ~ -maxdepth 3 -type l -exec test ! -e {} \; -print

# Remove problematic symlink
rm ~/.problematic-link

# Redeploy
bash scripts/dotfiles-deploy.sh
```

### Changes Not Showing Up

```bash
# Verify symlink exists
ls -la ~/.zshrc

# If it's a regular file (not symlink), stow didn't deploy it
# Possible causes:
# - Deployment script failed
# - File was modified after deployment

# Rerun deployment
bash scripts/dotfiles-deploy.sh

# Check git status
git status dotfiles/
```

### Need to Revert a Change

```bash
# See what changed in dotfiles
git diff dotfiles/

# Revert specific file
git checkout dotfiles/.zshrc

# Changes apply immediately (via symlink)

# Revert all changes
git checkout dotfiles/
```

## Best Practices

1. **Version control everything**: Commit dotfile changes with meaningful messages
2. **Document changes**: Add comments to config files explaining why
3. **Test changes**: Before committing, verify the app still works
4. **Keep it DRY**: Use sourcing/importing to avoid duplication
5. **Use .gitignore**: Don't commit sensitive data (api keys, tokens, etc.)
   - Use secrets/ directory instead (see SECRETS.md)
6. **Backup before major refactors**: Create git tag before big changes
7. **Link not copy**: Use symlinks (via stow) instead of copying files
8. **Document exceptions**: If a file shouldn't be symlinked, document why

## Related Documentation

- [Bootstrap Guide](../bootstrap/README.md) - Setting up on new machine
- [Secrets Management](./SECRETS.md) - Handling sensitive configuration
- [CLAUDE.md](../CLAUDE.md) - Project overview
