#!/bin/bash
# Updates dwm status bar by calling the statusbar script in a loop

while true; do
    xsetroot -name "$(/home/stevendejong/.dwm/statusbar/statusbar.sh)"
    sleep 1
done
