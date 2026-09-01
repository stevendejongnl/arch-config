#!/bin/sh

# Orange-colored Nerd Font battery glyph (U+F240). Icon color is fixed
# regardless of battery state — the percentage after it picks up state color.
# Bytes: \x0A (orange) + glyph UTF-8 + \x01 (reset) to isolate icon color.
ICON=$(printf '\x0a\xef\x89\x80\x01')

get_battery_state() {
  # Get battery info from acpi (redirect stderr to suppress errors)
  # Prioritize: charging > non-zero > fallback to any
  battery_info=$(acpi -b 2>/dev/null | grep "Charging" | head -n 1)

  if [ -z "$battery_info" ]; then
    battery_info=$(acpi -b 2>/dev/null | grep -v ", 0%" | head -n 1)
  fi

  if [ -z "$battery_info" ]; then
    battery_info=$(acpi -b 2>/dev/null | head -n 1)
  fi

  # Fallback: if acpi fails completely
  if [ -z "$battery_info" ]; then
    echo "$ICON$(printf '\x09') N/A $(printf '\x01')  "
    return
  fi

  # Extract percentage (primary parsing)
  percentage=$(echo "$battery_info" | awk -F ', ' '{print $2}' | awk '{print $1}' | tr -d '%')

  # Validate percentage is numeric (0-100)
  if ! echo "$percentage" | grep -Eq '^[0-9]+$'; then
    # Fallback: try regex parsing
    percentage=$(echo "$battery_info" | grep -oP '\d+(?=%)' | head -1)

    # Still invalid? Show unknown
    if ! echo "$percentage" | grep -Eq '^[0-9]+$'; then
      echo "$ICON$(printf '\x09') ??% $(printf '\x01')  "
      return
    fi
  fi

  # Clamp to valid range
  if [ "$percentage" -gt 100 ]; then
    percentage=100
  fi

  # Extract charging state (check if "Charging" or "Discharging" appears in first part)
  first_part=$(echo "$battery_info" | awk -F ', ' '{print $1}')
  if echo "$first_part" | grep -q "Charging"; then
    state="Charging"
  elif echo "$first_part" | grep -q "Discharging"; then
    state="Discharging"
  else
    # "Not charging" (plugged but not charging)
    state="NotCharging"
  fi

  # EDGE CASE: 0% while charging (brief transition state)
  if [ "$percentage" -eq 0 ] && [ "$state" = "Charging" ]; then
    echo "$ICON$(printf '\x09') 0% (initializing) $(printf '\x01')  "
    return
  fi

  # EDGE CASE: 0% not charging (critical failure)
  if [ "$percentage" -eq 0 ]; then
    echo "$ICON$(printf '\x0B') 0% (CRITICAL) $(printf '\x01')  "
    return
  fi

  # Pick value color based on state + percentage (icon stays orange).
  if [ "$state" = "Charging" ]; then
    value_color=$(printf '\x0C')   # green - charging
  elif [ "$state" = "Discharging" ]; then
    if [ "$percentage" -lt 15 ]; then
      value_color=$(printf '\x0B') # red - critical
    elif [ "$percentage" -lt 30 ]; then
      value_color=$(printf '\x0A') # orange - high warning
    elif [ "$percentage" -lt 50 ]; then
      value_color=$(printf '\x09') # yellow - medium
    else
      value_color=$(printf '\x08') # teal - good
    fi
  else
    # Not charging (plugged, full): green
    value_color=$(printf '\x0C')
  fi

  echo "$ICON$value_color $percentage% $(printf '\x01')  "
}

get_battery_state
