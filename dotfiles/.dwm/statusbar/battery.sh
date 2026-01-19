#!/bin/sh

get_battery_state() {
  battery_info=$(acpi -b | head -n 1)
  percentage=$(echo "$battery_info" | awk -F ', ' '{print $2}' | awk '{print $1}' | tr -d '%')
  state=$(echo "$battery_info" | awk -F ', ' '{print $1}' | awk '{print $3}')

  icon="🔋"
  if [ "$state" = "Charging" ]; then
    icon="⚡"
  fi

  # Color based on battery level
  if [ "$percentage" -lt 15 ]; then
    printf '\x0B'  # Critical - red
  elif [ "$percentage" -lt 30 ]; then
    printf '\x0A'  # High warning - orange
  elif [ "$percentage" -lt 50 ]; then
    printf '\x09'  # Medium - yellow
  else
    printf '\x08'  # Low/good - teal
  fi

  echo "$icon $percentage% $(printf '\x01')  "
}

get_battery_state
