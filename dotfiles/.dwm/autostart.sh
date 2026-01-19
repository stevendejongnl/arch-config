#! /bin/bash

autorandr --change &

xinput set-button-map 12 1 1 3 4 5 6 7 &

# sleep 5
darkman set dark &
systemctl --user restart wallpaper.service &
systemctl --user start autostart.target &
