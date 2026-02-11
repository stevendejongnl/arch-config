#!/bin/sh

get_battery_state() {
  # Get battery info from acpi (redirect stderr to suppress errors)
  battery_info=$(acpi -b 2>/dev/null | head -n 1)

  # Fallback: if acpi fails completely
  if [ -z "$battery_info" ]; then
    printf '\x09'  # Yellow - warning
    echo "🔋 N/A $(printf '\x01')  "
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
      printf '\x09'  # Yellow - warning
      echo "🔋 ??% $(printf '\x01')  "
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
    printf '\x09'  # Yellow - transitioning
    echo "⚡ 0% (initializing) $(printf '\x01')  "
    return
  fi

  # EDGE CASE: 0% not charging (critical failure)
  if [ "$percentage" -eq 0 ]; then
    printf '\x0B'  # Red - critical
    echo "🔋 0% (CRITICAL) $(printf '\x01')  "
    return
  fi

  # Enhanced icon logic
  icon="🔋"
  if [ "$state" = "Charging" ]; then
    icon="⚡"
  elif [ "$state" = "NotCharging" ] && [ "$percentage" -eq 100 ]; then
    icon="🔌"  # Full and plugged in
  fi

  # Color coding based on state and percentage
  if [ "$state" = "Charging" ]; then
    # Charging: always teal
    printf '\x08'
  elif [ "$state" = "Discharging" ]; then
    # Discharging: color based on percentage
    if [ "$percentage" -lt 15 ]; then
      printf '\x0B'  # Critical - red
    elif [ "$percentage" -lt 30 ]; then
      printf '\x0A'  # High warning - orange
    elif [ "$percentage" -lt 50 ]; then
      printf '\x09'  # Medium - yellow
    else
      printf '\x08'  # Good - teal
    fi
  else
    # Not charging (plugged but not charging): always teal
    printf '\x08'
  fi

  echo "$icon $percentage% $(printf '\x01')  "
}

get_battery_state
