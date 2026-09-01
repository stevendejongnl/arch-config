#!/bin/bash
# Updates dwm status bar by calling the statusbar script in a loop

# Kill any other instances running this script
pkill -f "update-statusbar.sh" 2>/dev/null || true
sleep 0.2  # brief pause to let old instances exit cleanly

# Start the update loop
while true; do
    xsetroot -name "$(/home/stevendejong/.dwm/statusbar/statusbar.sh)"
    sleep 1
done
