#!/bin/sh
# Right side of the tmux status bar: "now playing" (only while Playing) + clock.
# Rime theme — https://git.madebysteven.nl/stevendejong/rime

green='#[fg=#12141c,bg=#7fd88f,nobold,nounderscore,noitalics]'
purple='#[fg=#12141c,bg=#3ee6e0,nobold,nounderscore,noitalics]'
reset='#[fg=default,bg=default]'

if command -v playerctl >/dev/null 2>&1 && [ "$(playerctl status 2>/dev/null)" = "Playing" ]; then
    info=$(playerctl metadata --format '{{ trunc(artist, 12) }} — {{ trunc(title, 20) }}' 2>/dev/null)
    [ -n "$info" ] && printf '%s \xe2\x99\xab %s %s' "$green" "$info" "$reset"
fi

printf '%s %s %s' "$purple" "$(date '+%Y-%m-%d %H:%M')" "$reset"
