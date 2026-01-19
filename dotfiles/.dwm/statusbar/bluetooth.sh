#!/bin/bash

get_battery_percentage() {
  battery_info=$(echo -e "info $1\n" | bluetoothctl | grep "Battery\|Connected:")
  percentage=$(echo "$battery_info" | grep "Battery Percentage:" | awk '{print $3}')

  if [[ "$percentage" == *x* || "$percentage" == *X* ]]; then
    percentage_hex_format=$(echo "$percentage" | tr -dc '0-9a-fA-F')
    percentage=$((16#$percentage_hex_format))
  fi
  echo "$percentage"
}

get_device_name() {
  name_info=$(echo -e "info $1\n" | bluetoothctl | grep "Name:")
  name=$(echo "$name_info" | awk '{$1=""; print $0}' | xargs)

  echo "$name"
}

get_icon() {
  case $1 in
  "MDR-XB950N1")
    echo "🎧"
    ;;
  "MX Master 2S")
    echo "🖱️"
    ;;
  *)
    echo ""
    ;;
  esac
}

devices=$(echo -e "devices\n" | bluetoothctl | grep "Device " | awk '{print $2}')

for device in $devices; do
  percentage=$(get_battery_percentage "$device")
  if [ -n "$percentage" ]; then
    name=$(get_device_name "$device")
    icon=$(get_icon "$name")
    # Print device name, icon, address, and battery percentage
    # echo "Device Name: $name - Icon: $icon - Address: $device - Battery Percentage: $percentage%"

    echo "[ $icon $percentage% ]"
  fi
done
