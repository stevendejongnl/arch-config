#!/bin/bash
# Updates dwm status bar by calling the statusbar script in a loop

# Kill any other instances (using $$  to exclude current process)
pgrep -f "^bash.*update-statusbar.sh" | grep -v ^$$ | xargs kill 2>/dev/null || true

# Start the update loop
while true; do
    xsetroot -name "$(/home/stevendejong/.dwm/statusbar/statusbar.sh)"
    sleep 1
done
