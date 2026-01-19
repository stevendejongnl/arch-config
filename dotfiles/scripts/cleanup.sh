#!/usr/bin/env bash
# cleanup.sh - define a cleanup() function for interactive shells (zsh/bash)
# Source this file in your ~/.zshrc (or ~/.bashrc):
#   source $HOME/scripts/cleanup.sh
# Then run: cleanup [-n] [-d] [-a] [-i] [-k KEEP] [-y] [-v] [-h]
#
# This version avoids eval and avoids passing complex pipelines through a single eval string,
# which caused your earlier awk / globbing errors in zsh.

# If an alias named 'cleanup' exists, remove it so we can define the function.
unalias cleanup 2>/dev/null || true

cleanup() {
  local KEEP=1
  local DRY_RUN=0
  local DOCKER=0
  local AGGRESSIVE=0
  local IMAGES=0
  local ASSUME_YES=0
  local VERBOSE=0
  local OPTIND opt

  OPTIND=1
  # Added 'd' so combined flags like -di or -da work: -d is a docker-related flag (no-op by itself)
  while getopts "ndak:iyvh" opt; do
    case "$opt" in
      n) DRY_RUN=1 ;;
      d) DOCKER=1 ;;     # convenience flag so -di and -da don't error
      a) AGGRESSIVE=1 ;;
      i) IMAGES=1 ;;
      k) KEEP="$OPTARG" ;;
      y) ASSUME_YES=1 ;;
      v) VERBOSE=1 ;;
      h)
        cat <<EOF
Usage: cleanup [-n] [-d] [-a] [-i] [-k KEEP] [-y] [-v] [-h]
  -n  dry-run (show what would be done)
  -d  docker flag (convenience, can be combined with -a or -i)
  -a  docker prune aggressive (docker system prune -a --volumes)
  -i  docker prune images (docker system prune -a)
  -k  keep N versions with paccache (default: 1)
  -y  assume yes (skip confirmations)
  -v  verbose
  -h  help
EOF
        return 0
        ;;
      \?)
        printf 'Invalid option: -%s\n' "$OPTARG" >&2
        return 2
        ;;
    esac
  done
  shift $((OPTIND - 1))

  run_cmd() {
    # Run a simple command (no complex pipelines). Use it for single commands.
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] %s\n' "$*"
      return 0
    fi
    if [ "$VERBOSE" = "1" ]; then
      printf '[RUN] %s\n' "$*"
    fi
    "$@"
    return $?
  }

  confirm() {
    if [ "$ASSUME_YES" = "1" ] || [ "$DRY_RUN" = "1" ]; then
      return 0
    fi
    printf '%s [y/N] ' "$1" >&2
    local ans
    if ! read -r ans; then
      return 1
    fi
    case "$ans" in
      [yY]|[yY][eE][sS]) return 0 ;;
      *) return 1 ;;
    esac
  }

  printf '\nStarting cleanup (dry-run=%s, keep=%s, aggressive=%s, images=%s, docker=%s)\n' "$DRY_RUN" "$KEEP" "$AGGRESSIVE" "$IMAGES" "$DOCKER"

  # Keep sudo alive once (unless dry-run)
  if [ "$DRY_RUN" = "0" ] && command -v sudo >/dev/null 2>&1; then
    sudo -v || printf 'Warning: unable to refresh sudo credentials\n' >&2
  fi

  # 1) journalctl
  printf '\n1) journalctl -- show disk usage and vacuum to 2 weeks\n'
  # show disk usage (pipeline executed directly, not via run_cmd)
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY-RUN] sudo journalctl --disk-usage\n'
  else
    sudo journalctl --disk-usage || true
  fi
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY-RUN] sudo journalctl --vacuum-time=2weeks\n'
  else
    sudo journalctl --vacuum-time=2weeks || true
  fi

  # 2) /tmp cleanup
  printf '\n2) /tmp cleanup (top-level entries)\n'
  if confirm "Remove all top-level entries in /tmp?"; then
    if [ "$DRY_RUN" = "1" ]; then
      sudo find /tmp -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null || true
    else
      sudo find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + || true
    fi
  else
    printf 'Skipping /tmp cleanup\n'
  fi

  # 3) pacman cache cleanup
  printf '\n3) pacman cache cleanup\n'
  if [ "$DRY_RUN" = "1" ]; then
    sudo du -sh /var/cache/pacman/pkg 2>/dev/null || true
  else
    sudo du -sh /var/cache/pacman/pkg 2>/dev/null || true
  fi

  if command -v paccache >/dev/null 2>&1; then
    printf 'Using paccache - keeping %s version(s) per package\n' "$KEEP"
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] sudo paccache -rvk%s\n' "$KEEP"
    else
      sudo paccache -rvk"$KEEP" || true
    fi
  else
    printf 'paccache not found. Recommend installing pacman-contrib for safer cleanup.\n'
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] sudo pacman -S --noconfirm pacman-contrib; sudo paccache -rvk%s\n' "$KEEP"
    else
      if confirm "Install pacman-contrib and run paccache to clean cache? (recommended)"; then
        sudo pacman -S --noconfirm pacman-contrib || true
        sudo paccache -rvk"$KEEP" || true
      else
        if confirm "Aggressively remove all *.pkg.tar.zst from /var/cache/pacman/pkg?"; then
          sudo find /var/cache/pacman/pkg -maxdepth 1 -type f -name '*.pkg.tar.zst' -exec rm -v {} + || true
        else
          printf 'Skipping pacman cache deletion\n'
        fi
      fi
    fi
  fi

  # 4) Docker json logs truncation (safe)
  printf '\n4) Truncate docker container json logs (removes logs only)\n'
  # show sizes (run pipeline directly)
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY-RUN] show docker json log sizes\n'
    sudo find /var/lib/docker/containers -type f -name '*-json.log' -printf '%s\t%p\n' 2>/dev/null | sort -n | \
      awk '{printf "%.1f MB\t%s\n",$1/1024/1024,$2}' || true
  else
    sudo find /var/lib/docker/containers -type f -name '*-json.log' -printf '%s\t%p\n' 2>/dev/null | sort -n | \
      awk '{printf "%.1f MB\t%s\n",$1/1024/1024,$2}' || true
  fi

  if confirm "Truncate docker container json logs (this will remove log contents)?"; then
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] sudo find /var/lib/docker/containers -type f -name '\''*-json.log'\'' -exec truncate -s 0 {} +\n'
    else
      # run the actual truncate; keep the pattern quoted so zsh won't expand it before find sees it
      sudo find /var/lib/docker/containers -type f -name '*-json.log' -exec truncate -s 0 {} + || true
    fi
  else
    printf 'Skipping docker log truncation\n'
  fi

  # 5) Aggressive docker prune (optional)
  if [ "$AGGRESSIVE" = "1" ]; then
    printf '\n5) Aggressive Docker cleanup\n'
    if confirm "Run 'docker system prune -a --volumes' (removes unused images/containers/volumes)?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo docker system prune -a --volumes -f\n'
      else
        sudo docker system prune -a --volumes -f || true
      fi
    else
      printf 'Skipping aggressive docker prune\n'
    fi
  fi

  # 6) Docker images prune (optional)
  if [ "$IMAGES" = "1" ]; then
    printf '\n6) Docker images cleanup\n'
    if confirm "Run 'docker system prune -a' (removes unused images/containers)?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo docker system prune -a -f\n'
      else
        sudo docker system prune -a -f || true
      fi
    else
      printf 'Skipping docker images prune\n'
    fi
  fi

  # 7) Flatpak cleanup
  printf '\n7) Flatpak cleanup (remove unused runtimes)\n'
  if command -v flatpak >/dev/null 2>&1; then
    if confirm "Run 'flatpak uninstall --unused' and 'flatpak repair --system'?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo flatpak uninstall --unused -y; sudo flatpak repair --system\n'
      else
        sudo flatpak uninstall --unused -y || true
        sudo flatpak repair --system || true
      fi
    else
      printf 'Skipping flatpak cleanup\n'
    fi
  else
    printf 'flatpak not installed, skipping\n'
  fi

  # 8) Show largest files (>100MB) (top 20)
  printf '\n8) Largest files ( >100MB ) -- inspect before deleting anything manual\n'
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY-RUN] find / -xdev -type f -size +100M -printf ... | tail -n 20\n'
  else
    sudo find / -xdev -type f -size +100M -printf '%s\t%p\n' 2>/dev/null | sort -n | tail -n 20 | \
      awk '{printf "%.1f MB\t%s\n",$1/1024/1024,$2}' || true
  fi

  # Final: show disk usage
  printf '\nFinished. Current disk usage for / :\n'
  if [ "$DRY_RUN" = "1" ]; then
    df -h /
  else
    df -h /
  fi

  printf '\nRecommendation: after freeing space, run "sudo pacman -Syu" to perform upgrades.\n'
  return 0
}

# Info message when sourced interactively
if [ -n "${ZSH_VERSION-}${BASH_VERSION-}" ]; then
  printf 'Defined function cleanup(). Run "cleanup -n" to dry-run, then "cleanup" to execute.\n'
fi
