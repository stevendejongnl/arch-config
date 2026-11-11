#!/bin/sh
# Lock the screen with slock.
#   1. pause all media players and mute the sound (restored after unlock, playback stays paused)
#   2. blur the current wallpaper for every monitor into ~/.cache/slock/bg.ppm (slock reads it)
#   3. run slock
# "lock.sh --prepare" only builds the image, so it can be warmed up without locking.

cache="$HOME/.cache/slock"
image="$cache/bg.ppm"
keyfile="$cache/bg.key"
bgcolor="#12141C"

mkdir -p "$cache"

prepare_image() {
  wall=$(cat "$HOME/.config/wallpaper/current" 2>/dev/null)
  [ -f "$wall" ] || { rm -f "$image"; return 0; }

  total=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2; exit}')
  monitors=$(xrandr --listmonitors | sed -n 's/.* \([0-9]*\)\/[0-9]*x\([0-9]*\)\/[0-9]*+\([0-9]*\)+\([0-9]*\) .*/\1x\2+\3+\4/p')
  [ -n "$total" ] && [ -n "$monitors" ] || { rm -f "$image"; return 0; }

  key=$(printf 'v4|%s|%s|%s|%s' "$wall" "$(stat -c %Y "$wall")" "$total" "$monitors" | sha1sum | cut -d' ' -f1)
  [ -f "$image" ] && [ "$(cat "$keyfile" 2>/dev/null)" = "$key" ] && return 0

  set -- -size "$total" "canvas:$bgcolor"
  for geom in $monitors; do
    size=${geom%%+*}
    offset=+${geom#*+}
    offset=${offset%+*}+${geom##*+}
    # shrink, blur and grow again: a strong blur for little work, then dim it by 10%.
    # -clamp is needed: this ImageMagick is HDRI, so resizing overshoots past white and
    # -modulate turned those values into wrong colors in bright areas (smoke, sky)
    set -- "$@" '(' "$wall" -resize "${size}^" -gravity center -extent "$size" \
      -resize 12.5% -clamp -blur 0x2 -resize "${size}!" -clamp -evaluate Multiply 0.9 ')' \
      -gravity NorthWest -geometry "$offset" -composite
  done
  if magick "$@" -depth 8 "ppm:$image.tmp"; then
    mv "$image.tmp" "$image"
    echo "$key" > "$keyfile"
  else
    rm -f "$image.tmp" "$image"
  fi
}

prepare_image

[ "$1" = "--prepare" ] && exit 0

# Already locked
pgrep -x slock >/dev/null && exit 0

playerctl -a pause 2>/dev/null
was_muted=$(pamixer --get-mute 2>/dev/null)
pamixer --mute 2>/dev/null

# Fake kernel panic / bluescreen: never on arch-workstation, on computersloeber only at the
# office (autorandr profile "office"), always on the other machines.
host=$(sed -n 's/^host: *//p' "$HOME/.config/arch-config/config.yaml" 2>/dev/null)
case "$host" in
  arch-workstation) no_panic=1 ;;
  computersloeber) autorandr --current 2>/dev/null | grep -qx office || no_panic=1 ;;
esac
# Where there is no panic, the lock screen dims to 10% brightness after the same 2 minutes
# (any key brings it back), so the screen feels almost off.
if [ -n "${no_panic:-}" ]; then
  export SLOCK_PANIC_AFTER=0 SLOCK_DIM_AFTER=120
fi

slock
rc=$?

# Only unmute when sound was on before the lock
[ "$was_muted" = "false" ] && pamixer --unmute 2>/dev/null
exit $rc
