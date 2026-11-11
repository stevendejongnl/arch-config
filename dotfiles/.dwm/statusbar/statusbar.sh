#!/bin/sh

SLSTATUS_DIR="$HOME/.dwm/statusbar"
OUTPUT=""

get_cpu_usage() {
  OUTPUT+="$("$SLSTATUS_DIR"/cpu-usage.sh)"
}

get_memory_usage() {
  OUTPUT+="$("$SLSTATUS_DIR"/memory-usage.sh)"
}

get_package_updates() {
  # 0x12 = statuscmd byte for package updates (clickable)
  OUTPUT+="$(printf '\x12')$("$SLSTATUS_DIR"/package-updates.sh)"
}

get_pipewire() {
  OUTPUT+="$("$SLSTATUS_DIR"/pipewire.sh)"
}

get_bluetooth() {
  OUTPUT+="$("$SLSTATUS_DIR"/bluetooth.sh)"
}

get_sysmon() {
  OUTPUT+="$(sysmon status) "
}

get_date() {
  # 0x11 = statuscmd byte for date (clickable)
  # Calendar glyph (U+F073), then dd-mm hh:mm in the normal status color
  OUTPUT+="$(printf '\x11')$(printf '\xef\x81\xb3') $(date '+%d-%m %H:%M')$(printf '\x01')  "
}

get_keito() {
  OUTPUT+="$("$SLSTATUS_DIR"/keito.sh)"
}

get_sysmon
get_package_updates
get_date

# Writes the Spotify playing state for dwm, prints nothing
"$SLSTATUS_DIR"/shared-tag-playing.sh

# Keito timer: only when this machine has the API creds (work laptop).
[ -f "$SLSTATUS_DIR/keito/.env" ] && get_keito

# get_cpu_usage
# get_memory_usage
# get_pipewire
# get_bluetooth

printf "%s" "$OUTPUT"
