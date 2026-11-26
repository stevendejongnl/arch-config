#!/bin/bash

# Nerd Font archive glyph (U+F187)
ICON=$(printf '\xef\x86\x87')

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
    # checkupdates exits 0 with updates, 2 with none and 1 on an error (offline, VPN down). An error must
    # not count as zero updates, so the old numbers stay until a check works.
    old_arch=0
    old_aur=0
    if [ -f "$status_file" ]; then
        IFS=/ read -r old_arch old_aur < "$status_file"
    fi

    arch_list=$(checkupdates 2>/dev/null)
    case $? in
        0) updates_arch=$(echo "$arch_list" | wc -l) ;;
        2) updates_arch=0 ;;
        *) updates_arch=$old_arch ;;
    esac

    if aur_list=$(yay -Qum 2>/dev/null); then
        updates_aur=$(printf '%s' "$aur_list" | grep -c .)
    else
        updates_aur=$old_aur
    fi

    echo "$updates_arch/$updates_aur" > "$status_file"
    echo "$current_time" > "$last_run_file"
fi

if [ -f "$status_file" ]; then
    read -r status < "$status_file"
else
    status="0/0"
fi

# Shown only when updates pile up: a yellow chip from 5, orange from 20, red from 50.
if [ "$status" != "0/0" ]; then
    updates_arch=$(echo "$status" | cut -d'/' -f1)
    updates_aur=$(echo "$status" | cut -d'/' -f2)
    total=$((updates_arch + updates_aur))

    if [ "$total" -ge 50 ]; then
        badge=$(printf '\x05')  # red chip
    elif [ "$total" -ge 20 ]; then
        badge=$(printf '\x03')  # orange chip
    elif [ "$total" -ge 5 ]; then
        badge=$(printf '\x02')  # yellow chip
    else
        exit 0
    fi

    printf '%s %s %s %s ' "$badge" "$ICON" "$status" "$(printf '\x01')"
fi
