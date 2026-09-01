#!/usr/bin/env bash
# cleanup.sh - define a cleanup() function for interactive shells (zsh/bash)
# Source this file in your ~/.zshrc (or ~/.bashrc):
#   source $HOME/scripts/cleanup.sh
# Then run: cleanup [-n] [-c] [-b] [-d] [-a] [-i] [-k KEEP] [-s] [-y] [-v] [-h]
#
# Three-phase design:
#   Phase 1: Launch background size probes + large-file scan
#   Phase 2: Wait for probes, print summary table
#   Phase 3: Confirm and clean each target sequentially
#
# New flags:
#   -c  include dev caches (npm, uv, pip, pnpm, cargo, go, yay, pre-commit, pypoetry, Cypress)
#   -b  include browser caches (Chromium, Google Chrome)
#   -s  skip large-file scan (fast mode)

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
  local CLEAN_CACHES=0
  local CLEAN_BROWSERS=0
  local SKIP_SCAN=0
  local OPTIND opt

  OPTIND=1
  while getopts "ndak:iycbsyvh" opt; do
    case "$opt" in
      n) DRY_RUN=1 ;;
      d) DOCKER=1 ;;
      a) AGGRESSIVE=1 ;;
      i) IMAGES=1 ;;
      k) KEEP="$OPTARG" ;;
      y) ASSUME_YES=1 ;;
      c) CLEAN_CACHES=1 ;;
      b) CLEAN_BROWSERS=1 ;;
      s) SKIP_SCAN=1 ;;
      v) VERBOSE=1 ;;
      h)
        cat <<EOF
Usage: cleanup [-n] [-c] [-b] [-d] [-a] [-i] [-k KEEP] [-s] [-y] [-v] [-h]
  -n  dry-run (show what would be done)
  -c  dev caches (npm, uv, pip, pnpm, cargo, go, yay, pre-commit, pypoetry, Cypress)
  -b  browser caches (Chromium, Google Chrome)
  -d  docker flag (convenience, can be combined with -a or -i)
  -a  docker prune aggressive (docker system prune -a --volumes)
  -i  docker prune images (docker system prune -a)
  -k  keep N versions with paccache (default: 1)
  -s  skip large-file scan (fast mode)
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

  # Guard: refuse to run as root
  if [ "${EUID:-$(id -u)}" = "0" ]; then
    printf 'Error: cleanup() must not be run as root.\n' >&2
    printf 'Run as a regular user with sudo available.\n' >&2
    return 1
  fi

  # Helper functions
  run_cmd() {
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

  _read_sz() {
    cat "$TMPDIR_CLEANUP/$1" 2>/dev/null | tr -d '[:space:]'
  }

  # === PHASE 1: Setup and launch background jobs ===
  printf '\nStarting cleanup (dry-run=%s, keep=%s, caches=%s, browsers=%s, skip-scan=%s)\n' \
    "$DRY_RUN" "$KEEP" "$CLEAN_CACHES" "$CLEAN_BROWSERS" "$SKIP_SCAN"

  local TMPDIR_CLEANUP
  TMPDIR_CLEANUP=$(mktemp -d /tmp/cleanup-XXXXXX)
  trap 'rm -rf "$TMPDIR_CLEANUP"' EXIT INT TERM

  # Keep sudo alive once (unless dry-run)
  if [ "$DRY_RUN" = "0" ] && command -v sudo >/dev/null 2>&1; then
    sudo -v || printf 'Warning: unable to refresh sudo credentials\n' >&2
  fi

  # Launch all size probes in parallel
  { du -sh ~/.local/share/Trash 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_trash" &
  { du -sh ~/.cache/thumbnails 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_thumb" &
  { du -sh /var/lib/systemd/coredump 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_coredump" &
  { du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_pacman" &
  { sudo find /var/lib/docker/containers -name '*-json.log' -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {printf "%.0fM", s/1024/1024}'; } > "$TMPDIR_CLEANUP/sz_dockerlog" &
  { pacman -Qtdq 2>/dev/null | wc -l | tr -d ' '; } > "$TMPDIR_CLEANUP/sz_orphans" &

  if [ "$CLEAN_CACHES" = "1" ]; then
    { du -sh ~/.npm 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_npm" &
    { du -sh "$(uv cache dir 2>/dev/null)" 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_uv" &
    { du -sh ~/.cache/pip 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_pip" &
    { du -sh ~/.local/share/pnpm 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_pnpm" &
    { du -sh ~/.cargo/registry/cache 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_cargo" &
    { du -sh ~/go/pkg/mod/cache 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_go" &
    { du -sh ~/.cache/yay 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_yay" &
    { du -sh ~/.cache/pre-commit 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_precommit" &
    { du -sh ~/.cache/pypoetry 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_pypoetry" &
    { du -sh ~/.cache/Cypress 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_cypress" &
  fi

  if [ "$CLEAN_BROWSERS" = "1" ]; then
    { du -sh ~/.cache/chromium 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_chromium" &
    { du -sh ~/.cache/google-chrome 2>/dev/null | cut -f1; } > "$TMPDIR_CLEANUP/sz_chrome" &
  fi

  # Launch large-file scan in background (slow, let it run during phase 2 and 3)
  local PID_SCAN=""
  if [ "$SKIP_SCAN" = "0" ] && [ "$DRY_RUN" = "0" ]; then
    { sudo find / -xdev -type f -size +100M -printf '%s\t%p\n' 2>/dev/null | \
      sort -n | tail -n 30 | \
      awk '{printf "%6.0f MB  %s\n", $1/1024/1024, $2}'; } \
      > "$TMPDIR_CLEANUP/largefile_scan" &
    PID_SCAN=$!
  fi

  # === PHASE 2: Wait for size probes and print summary ===
  printf '\n[Phase 2] Waiting for size calculations...\n'
  wait 2>/dev/null

  printf '\n========================================\n'
  printf ' CLEANUP SUMMARY\n'
  printf '========================================\n'
  printf '  Systemd coredumps        %s\n' "$(_read_sz sz_coredump)"
  printf '  Trash                    %s\n' "$(_read_sz sz_trash)"
  printf '  Thumbnail cache          %s\n' "$(_read_sz sz_thumb)"
  printf '  Orphaned packages        %s pkgs\n' "$(_read_sz sz_orphans)"
  printf '  Pacman pkg cache         %s\n' "$(_read_sz sz_pacman)"
  printf '  Docker json logs         %s\n' "$(_read_sz sz_dockerlog)"

  if [ "$CLEAN_CACHES" = "1" ]; then
    printf '  \n'
    printf '  pip cache                %s\n' "$(_read_sz sz_pip)"
    printf '  uv cache                 %s\n' "$(_read_sz sz_uv)"
    printf '  npm cache                %s\n' "$(_read_sz sz_npm)"
    printf '  pnpm store               %s\n' "$(_read_sz sz_pnpm)"
    printf '  cargo registry           %s\n' "$(_read_sz sz_cargo)"
    printf '  Go module cache          %s\n' "$(_read_sz sz_go)"
    printf '  yay build cache          %s\n' "$(_read_sz sz_yay)"
    printf '  pre-commit cache         %s\n' "$(_read_sz sz_precommit)"
    printf '  pypoetry cache           %s\n' "$(_read_sz sz_pypoetry)"
    printf '  Cypress cache            %s\n' "$(_read_sz sz_cypress)"
  fi

  if [ "$CLEAN_BROWSERS" = "1" ]; then
    printf '  \n'
    printf '  Chromium cache           %s\n' "$(_read_sz sz_chromium)"
    printf '  Google Chrome cache      %s\n' "$(_read_sz sz_chrome)"
  fi

  printf '========================================\n'
  if [ "$SKIP_SCAN" = "0" ]; then
    printf '  Large file scan: running in background\n'
  fi
  printf '========================================\n\n'

  # === PHASE 3: Interactive cleanup (sequential) ===
  printf '[Phase 3] Starting cleanup with confirmations...\n\n'

  # 1) journalctl vacuum (no confirm, always safe)
  printf '1) journalctl -- vacuum to 2 weeks\n'
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY-RUN] sudo journalctl --vacuum-time=2weeks\n'
  else
    sudo journalctl --vacuum-time=2weeks || true
  fi

  # 2) Systemd coredumps
  printf '\n2) Systemd coredumps\n'
  if confirm "Remove /var/lib/systemd/coredump/*?"; then
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] sudo rm -rf /var/lib/systemd/coredump/*\n'
    else
      sudo rm -rf /var/lib/systemd/coredump/* || true
    fi
  else
    printf 'Skipping systemd coredump removal\n'
  fi

  # 3) Trash
  printf '\n3) Trash directory\n'
  if confirm "Remove ~/.local/share/Trash/*?"; then
    run_cmd rm -rf ~/.local/share/Trash/*
  else
    printf 'Skipping trash removal\n'
  fi

  # 4) Thumbnail cache
  printf '\n4) Thumbnail cache\n'
  if confirm "Remove ~/.cache/thumbnails/*?"; then
    run_cmd rm -rf ~/.cache/thumbnails/*
  else
    printf 'Skipping thumbnail cache removal\n'
  fi

  # 5) /tmp cleanup
  printf '\n5) /tmp cleanup (top-level entries)\n'
  if confirm "Remove all top-level entries in /tmp?"; then
    if [ "$DRY_RUN" = "1" ]; then
      sudo find /tmp -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null || true
    else
      sudo find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + || true
    fi
  else
    printf 'Skipping /tmp cleanup\n'
  fi

  # 6) Orphaned pacman packages
  printf '\n6) Orphaned pacman packages\n'
  local ORPHAN_COUNT
  ORPHAN_COUNT=$(_read_sz sz_orphans)
  if [ "${ORPHAN_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    if confirm "Remove $ORPHAN_COUNT orphaned packages?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] pacman -Qtdq | sudo pacman -Rns -\n'
      else
        pacman -Qtdq 2>/dev/null | sudo pacman -Rns - || true
      fi
    fi
  else
    printf 'No orphaned packages found\n'
  fi

  # 7) Pacman cache cleanup
  printf '\n7) Pacman cache cleanup\n'
  if command -v paccache >/dev/null 2>&1; then
    printf 'Using paccache - keeping %s version(s) per package\n' "$KEEP"
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] sudo paccache -rvk%s\n' "$KEEP"
    else
      sudo paccache -rvk"$KEEP" || true
    fi
  else
    printf 'paccache not found. Recommend installing pacman-contrib for safer cleanup.\n'
    if confirm "Install pacman-contrib and run paccache to clean cache?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo pacman -S --noconfirm pacman-contrib; sudo paccache -rvk%s\n' "$KEEP"
      else
        sudo pacman -S --noconfirm pacman-contrib || true
        sudo paccache -rvk"$KEEP" || true
      fi
    fi
  fi

  # 8) Docker json logs truncation
  printf '\n8) Docker json logs\n'
  if confirm "Truncate docker container json logs (removes log contents)?"; then
    if [ "$DRY_RUN" = "1" ]; then
      printf '[DRY-RUN] sudo find /var/lib/docker/containers -type f -name '\''*-json.log'\'' -exec truncate -s 0 {} +\n'
    else
      sudo find /var/lib/docker/containers -type f -name '*-json.log' -exec truncate -s 0 {} + || true
    fi
  else
    printf 'Skipping docker log truncation\n'
  fi

  # 9) Aggressive docker prune (optional, only with -a)
  if [ "$AGGRESSIVE" = "1" ]; then
    printf '\n9) Aggressive Docker cleanup\n'
    if confirm "Run 'docker system prune -a --volumes' (removes unused images/containers/volumes)?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo docker system prune -a --volumes -f\n'
      else
        sudo docker system prune -a --volumes -f || true
      fi
    fi
  fi

  # 10) Docker images prune (optional, only with -i)
  if [ "$IMAGES" = "1" ]; then
    printf '\n10) Docker images cleanup\n'
    if confirm "Run 'docker system prune -a' (removes unused images/containers)?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo docker system prune -a -f\n'
      else
        sudo docker system prune -a -f || true
      fi
    fi
  fi

  # 11) Flatpak cleanup
  printf '\n11) Flatpak cleanup\n'
  if command -v flatpak >/dev/null 2>&1; then
    if confirm "Run 'flatpak uninstall --unused' and 'flatpak repair --system'?"; then
      if [ "$DRY_RUN" = "1" ]; then
        printf '[DRY-RUN] sudo flatpak uninstall --unused -y; sudo flatpak repair --system\n'
      else
        sudo flatpak uninstall --unused -y || true
        sudo flatpak repair --system || true
      fi
    fi
  fi

  # 12-21) Dev caches (only with -c)
  local STEP=12
  if [ "$CLEAN_CACHES" = "1" ]; then
    printf '\n%d) pip cache\n' "$STEP"
    if command -v pip >/dev/null 2>&1; then
      if confirm "Run 'pip cache purge'?"; then
        run_cmd pip cache purge
      fi
    fi
    ((STEP++))

    printf '\n%d) uv cache\n' "$STEP"
    if command -v uv >/dev/null 2>&1; then
      if confirm "Run 'uv cache clean'?"; then
        run_cmd uv cache clean
      fi
    fi
    ((STEP++))

    printf '\n%d) npm cache\n' "$STEP"
    if command -v npm >/dev/null 2>&1; then
      if confirm "Run 'npm cache clean --force'?"; then
        run_cmd npm cache clean --force
      fi
    fi
    ((STEP++))

    printf '\n%d) pnpm store\n' "$STEP"
    if command -v pnpm >/dev/null 2>&1; then
      if confirm "Run 'pnpm store prune'?"; then
        run_cmd pnpm store prune
      fi
    fi
    ((STEP++))

    printf '\n%d) yarn cache\n' "$STEP"
    if command -v yarn >/dev/null 2>&1; then
      if confirm "Run 'yarn cache clean'?"; then
        run_cmd yarn cache clean
      fi
    fi
    ((STEP++))

    printf '\n%d) cargo registry\n' "$STEP"
    if confirm "Remove ~/.cargo/registry/cache? (forces re-download on next build)"; then
      run_cmd rm -rf ~/.cargo/registry/cache
    fi
    ((STEP++))

    printf '\n%d) Go module cache\n' "$STEP"
    if command -v go >/dev/null 2>&1; then
      if confirm "Run 'go clean -modcache'? (forces re-download on next build)"; then
        run_cmd go clean -modcache
      fi
    fi
    ((STEP++))

    printf '\n%d) yay build cache\n' "$STEP"
    if confirm "Remove ~/.cache/yay? (AUR packages will re-download)"; then
      run_cmd rm -rf ~/.cache/yay
    fi
    ((STEP++))

    printf '\n%d) pre-commit cache\n' "$STEP"
    if confirm "Remove ~/.cache/pre-commit?"; then
      run_cmd rm -rf ~/.cache/pre-commit
    fi
    ((STEP++))

    printf '\n%d) pypoetry cache\n' "$STEP"
    if confirm "Remove ~/.cache/pypoetry?"; then
      run_cmd rm -rf ~/.cache/pypoetry
    fi
    ((STEP++))

    printf '\n%d) Cypress cache\n' "$STEP"
    if confirm "Remove ~/.cache/Cypress?"; then
      run_cmd rm -rf ~/.cache/Cypress
    fi
    ((STEP++))
  fi

  # 23-24) Browser caches (only with -b)
  if [ "$CLEAN_BROWSERS" = "1" ]; then
    printf '\n%d) Chromium cache\n' "$STEP"
    if pgrep -x chromium >/dev/null 2>&1; then
      printf 'Warning: Chromium appears to be running. Close it before clearing cache.\n'
    fi
    if confirm "Remove ~/.cache/chromium?"; then
      run_cmd rm -rf ~/.cache/chromium
    fi
    ((STEP++))

    printf '\n%d) Google Chrome cache\n' "$STEP"
    if pgrep -x "google-chrome" >/dev/null 2>&1; then
      printf 'Warning: Google Chrome appears to be running. Close it before clearing cache.\n'
    fi
    if confirm "Remove ~/.cache/google-chrome?"; then
      run_cmd rm -rf ~/.cache/google-chrome
    fi
  fi

  # Final: show disk usage and large file results
  printf '\n\nFinished. Current disk usage for / :\n'
  df -h /

  if [ -n "$PID_SCAN" ] && kill -0 "$PID_SCAN" 2>/dev/null; then
    printf '\n[Waiting for large-file scan to complete...]\n'
    wait "$PID_SCAN" 2>/dev/null
  fi

  if [ -f "$TMPDIR_CLEANUP/largefile_scan" ]; then
    printf '\nLargest files (>100MB, top 30):\n'
    cat "$TMPDIR_CLEANUP/largefile_scan"
  fi

  printf '\nRecommendation: after freeing space, run "sudo pacman -Syu" to perform upgrades.\n'
  return 0
}

# If executed directly (not sourced), invoke the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  cleanup "$@"
  exit $?
fi

# Info message when sourced interactively
if [[ $- == *i* ]]; then
  printf 'Defined function cleanup(). Run "cleanup -n" to dry-run, then "cleanup" to execute.\n'
fi
