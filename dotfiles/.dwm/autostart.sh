#! /bin/bash

# Skip on dwm restart — session file only exists during restoreafterrestart
[ -f /tmp/dwm-session ] && exit 0

autorandr --change &

# sleep 5
gsettings set org.gnome.desktop.interface color-scheme prefer-dark &  # locked dark (modules/dark-mode.yaml)
systemctl --user restart wallpaper.service &
systemctl --user start autostart.target &

watch-screenshots &

# Start statusbar updater loop
nohup bash -c 'while true; do xsetroot -name "$($HOME/.dwm/statusbar/statusbar.sh)"; sleep 1; done' > /tmp/statusbar.log 2>&1 &
