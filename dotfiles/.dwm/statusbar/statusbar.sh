#!/bin/sh

SLSTATUS_DIR="$HOME/.dwm/statusbar"
OUTPUT=""

get_claude_usage() {
  OUTPUT+="$(printf '\x0C')🤖 $(claude-usage-statusbar) $(printf '\x01')  "
}

get_battery_state() {
  # 0x10 = statuscmd byte for battery (clickable)
  OUTPUT+="$(printf '\x10')$("$SLSTATUS_DIR"/battery.sh)"
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

get_date() {
  # 0x11 = statuscmd byte for date (clickable)
  OUTPUT+="$(printf '\x11')$(printf '\x08')🕐 $(date '+%d-%m-%Y %H:%M:%S') $(printf '\x01')  "
}

get_claude_usage
get_date
get_battery_state
# get_cpu_usage
# get_memory_usage
get_package_updates
# get_pipewire
# get_bluetooth

printf "%s" "$OUTPUT"
