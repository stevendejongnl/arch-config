#!/bin/sh

SLSTATUS_DIR="$HOME/.dwm/statusbar"
OUTPUT=""

get_battery_state() {
  # 0x10 = statuscmd byte for battery (clickable)
  OUTPUT+="$(printf '\x10')$("$SLSTATUS_DIR"/battery.sh) "
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
  OUTPUT+="$(sysmon status) "
}

get_date() {
  # 0x11 = statuscmd byte for date (clickable)
  # Yellow clock glyph (U+F017), norm-colored time
  OUTPUT+="$(printf '\x11')$(printf '\x09')$(printf '\xef\x80\x97') $(printf '\x01')$(date '+%d-%m-%Y %H:%M:%S') $(printf '\x01')  "
}

get_harvest() {
  OUTPUT+="$("$SLSTATUS_DIR"/harvest.sh)"
}

get_sysmon
get_date

# Harvest timer: only when this machine has the API creds (work laptop).
[ -f "$SLSTATUS_DIR/harvest/.env" ] && get_harvest

# Battery: only on machines that actually have one (skips desktops).
for _bat in /sys/class/power_supply/BAT*; do
  [ -e "$_bat" ] && { get_battery_state; break; }
done

# get_cpu_usage
# get_memory_usage
get_package_updates
# get_pipewire
# get_bluetooth

printf "%s" "$OUTPUT"
