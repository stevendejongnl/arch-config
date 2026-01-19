#!/usr/bin/env bash

# Get formatted notifications
notifications=$(dunstctl history | jq -r '
  .data[][] | 
  "<span weight=\"bold\">\(.appname.data // "Unknown")</span>  <span size=\"small\" alpha=\"60%\">\(.timestamp)</span>
<b>\(.summary.data // "")</b>
\(.body.data // "")

"
')

if [ -z "$notifications" ] || [ "$notifications" = "null" ]; then
    rofi -e "No notifications"
    exit 0
fi

# Show with rofi
selected=$(echo -e "Clear All\n---\n$notifications" | rofi \
    -dmenu \
    -markup-rows \
    -p "Notification Center" \
    -theme-str 'window {width: 700px; height: 500px;}' \
    -theme-str 'listview {lines: 20; columns: 1;}' \
    -theme-str 'element {padding: 8px;}')

# Handle actions
if [ "$selected" = "Clear All" ]; then
    dunstctl history-clear
    notify-send "Notification Center" "History cleared"
fi
