#!/usr/bin/env bash
# GRUB bootloader + the personal "Nova" theme (github.com/stevendejongnl/grub-nova).
# - clones/updates ~/workspace/builds/grub-nova
# - installs GRUB to the ESP if it isn't the active bootloader yet
#   (archinstall may have left the machine on systemd-boot; it is kept as a
#    fallback, not removed)
# - turns on os-prober (Windows / other-OS detection) and points GRUB at Nova
# - regenerates grub.cfg
# Idempotent — safe to re-run on every `dcli sync`.
set -u

if [ "$(id -u)" -eq 0 ]; then
  HOME_DIR=$(eval echo "~${SUDO_USER:-root}")
  run_as_user() { [ -n "${SUDO_USER:-}" ] && sudo -u "$SUDO_USER" "$@" || "$@"; }
else
  HOME_DIR="$HOME"
  run_as_user() { "$@"; }
fi

REPO_URL="git@github.com:stevendejongnl/grub-nova.git"
SRC_DIR="$HOME_DIR/workspace/builds/grub-nova"
ESP="/boot"
THEME_DST="/usr/share/grub/themes/nova"

# --- get the theme repo ----------------------------------------------------
if [ -d "$SRC_DIR/.git" ]; then
  echo "[grub-theme] updating $SRC_DIR"
  run_as_user git -C "$SRC_DIR" pull --ff-only origin main || \
    echo "[grub-theme]   (pull failed — using existing checkout)"
else
  echo "[grub-theme] cloning grub-nova -> $SRC_DIR"
  run_as_user mkdir -p "$(dirname "$SRC_DIR")"
  run_as_user git clone "$REPO_URL" "$SRC_DIR" || {
    echo "[grub-theme] ERROR: clone failed (SSH auth / network)"; exit 1; }
fi
[ -d "$SRC_DIR/themes/nova" ] || { echo "[grub-theme] ERROR: themes/nova missing"; exit 1; }

# --- only proceed on a GRUB-capable (EFI) machine -------------------------
if ! command -v grub-mkconfig >/dev/null 2>&1; then
  echo "[grub-theme] grub not installed — skipping"; exit 0
fi

# --- /etc/default/grub knobs (preserve existing cmdline) -----------------
set_kv() {  # key value
  local k=$1 v=$2 f=/etc/default/grub
  if grep -qE "^\s*#?\s*${k}=" "$f"; then
    sed -i -E "s|^\s*#?\s*${k}=.*|${k}=${v}|" "$f"
  else
    printf '%s=%s\n' "$k" "$v" >> "$f"
  fi
}
set_kv GRUB_DISABLE_OS_PROBER 'false'
set_kv GRUB_THEME "\"$THEME_DST/theme.txt\""
grep -qE '^\s*GRUB_GFXMODE=' /etc/default/grub || set_kv GRUB_GFXMODE '"1920x1080,auto"'

# --- install the theme --------------------------------------------------
rm -rf "$THEME_DST"
mkdir -p "$(dirname "$THEME_DST")"
cp -r "$SRC_DIR/themes/nova" "$THEME_DST"
echo "[grub-theme] installed Nova -> $THEME_DST"

# --- make GRUB the bootloader if it isn't already ----------------------
if [ ! -f "$ESP/grub/grub.cfg" ] || ! efibootmgr 2>/dev/null | grep -qE '^Boot[0-9A-F]{4}\*? +GRUB$'; then
  echo "[grub-theme] installing GRUB to $ESP (systemd-boot left as fallback)"
  grub-install --target=x86_64-efi --efi-directory="$ESP" --bootloader-id=GRUB --recheck
  grub_num=$(efibootmgr | sed -nE 's/^Boot([0-9A-F]{4})\*? +GRUB$/\1/p' | head -1)
  if [ -n "${grub_num:-}" ]; then
    rest=$(efibootmgr | sed -nE 's/^BootOrder: (.*)/\1/p' | tr ',' '\n' | grep -v "^${grub_num}$" | paste -sd,)
    efibootmgr -o "${grub_num}${rest:+,$rest}" >/dev/null
  fi
fi

echo "[grub-theme] grub-mkconfig -o $ESP/grub/grub.cfg"
grub-mkconfig -o "$ESP/grub/grub.cfg"
echo "[grub-theme] done"
