#!/bin/sh

SLSTATUS_DIR="$HOME/.dwm/statusbar"
OUTPUT=""

# The popup (dwm-popup.py) writes the name of its open tab here. The chip of that tab gets the
# selected (cyan, escape 0x04) badge: a chip starts with its click byte and its badge byte.
ACTIVE_TAB=$(cat "${XDG_RUNTIME_DIR:-/tmp}/dwm-popup-tab" 2>/dev/null)
select_chip() {
  if [ "$ACTIVE_TAB" = "$1" ]; then
    printf '%s' "$2" | LC_ALL=C sed 's/^\(.\)./\1\x04/'
  else
    printf '%s' "$2"
  fi
}

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
  # sysmon prints nothing while disk and RAM are both healthy; only then skip the separator
  SYSMON="$(sysmon status)"
  [ -n "$SYSMON" ] && OUTPUT+="$SYSMON "
}

get_date() {
  # 0x11 = statuscmd byte for date (clickable, opens the Calendar tab of the popup)
  # A grey chip like the Keito and Claude chips: calendar glyph (U+F073), then dd-mm hh:mm
  OUTPUT+="$(select_chip calendar "$(printf '\x11\x0e') $(printf '\xef\x81\xb3') $(date '+%d-%m %H:%M') $(printf '\x01') ")"
}

get_claude_usage() {
  # 0x14 = statuscmd byte for the Claude usage popup (clickable, printed by the script)
  OUTPUT+="$(select_chip claude "$("$SLSTATUS_DIR"/claude-usage.sh)")"
}

get_case_dot() {
  # Only machines with case lights (the workstation) get the dot, see case-lights.sh
  "$SLSTATUS_DIR"/case-lights.sh || return 0
  # 0x16 = statuscmd byte for the Case tab (clickable), 0x06 = dwm escape for the dot in the colour of the PC case.
  # The colour is read by dwm itself from ~/.config/case-color, so this text never changes.
  OUTPUT+="$(printf '\x16\x06 \xef\x84\x91 \x01')"
}

get_notifications() {
  # 0x15 = statuscmd byte for the notifications popup (clickable, printed by the script)
  OUTPUT+="$(select_chip notifications "$("$SLSTATUS_DIR"/notifications.sh)")"
}

get_keito() {
  OUTPUT+="$(select_chip keito "$("$SLSTATUS_DIR"/keito.sh)")"
}

# Writes the Spotify playing state for dwm, prints nothing
"$SLSTATUS_DIR"/shared-tag-playing.sh

get_sysmon
get_package_updates

get_case_dot
get_claude_usage
get_date

# Keito timer: only when this machine has the API creds (work laptop).
[ -f "$SLSTATUS_DIR/keito/.env" ] && get_keito
get_notifications

# get_cpu_usage
# get_memory_usage
# get_pipewire
# get_bluetooth

printf "%s" "$OUTPUT"
