#!/bin/bash

# Red-colored Nerd Font archive glyph (U+F187). Icon is always red for
# emphasis; the count after it picks up count-based color.
# Bytes: \x0B (red) + glyph UTF-8 + \x01 (reset).
ICON=$(printf '\x0b\xef\x86\x87\x01')

status_file="$HOME/.dwm/statusbar/package-updates/status"
last_run_file="$HOME/.dwm/statusbar/package-updates/last-run"

interval=$((30 * 60))  # 30 minutes

format() {
    if [ "$1" -eq 0 ]; then
        echo '0'
    else
        echo "$1"
    fi
}

current_time=$(date +%s)
if [ -f "$last_run_file" ]; then
    last_run=$(cat "$last_run_file")
else
    last_run=0
fi

if [ "$((current_time - last_run))" -ge "$interval" ]; then
    if ! updates_arch=$(checkupdates | wc -l); then
        updates_arch=0
    fi

    if ! updates_aur=$(yay -Qum 2>/dev/null | wc -l); then
        updates_aur=0
    fi

    # updates="$((updates_arch + updates_aur))"

    echo "$updates_arch/$updates_aur" > "$status_file"
    echo "$current_time" > "$last_run_file"
fi

if [ -f "$status_file" ]; then
    read -r status < "$status_file"
else
    status="0/0"
fi

if [ "$status" != "0/0" ]; then
    updates_arch=$(echo "$status" | cut -d'/' -f1)
    updates_aur=$(echo "$status" | cut -d'/' -f2)
    total=$((updates_arch + updates_aur))

    # Count-based color for the value (icon stays red).
    if [ "$total" -ge 50 ]; then
        value_color=$(printf '\x0B')  # critical
    elif [ "$total" -ge 20 ]; then
        value_color=$(printf '\x0A')  # high
    elif [ "$total" -ge 5 ]; then
        value_color=$(printf '\x09')  # medium
    else
        value_color=$(printf '\x0C')  # green — few updates
    fi

    echo "$ICON$value_color $status $(printf '\x01')  "
else
    echo "$ICON$(printf '\x0C') 0/0 $(printf '\x01')  "
fi
