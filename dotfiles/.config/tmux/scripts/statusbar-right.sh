#!/bin/sh
# Right side of the tmux status bar: "now playing" (only while Playing) + clock.
# Flat theme: plain secondary text, no filled blocks.

dim='#[fg=#a8a9ad,bg=default,nobold,nounderscore,noitalics]'
ink='#[fg=#ecebe6,bg=default,nobold,nounderscore,noitalics]'
reset='#[fg=default,bg=default]'

if command -v playerctl >/dev/null 2>&1 && [ "$(playerctl status 2>/dev/null)" = "Playing" ]; then
    info=$(playerctl metadata --format '{{ trunc(artist, 12) }} — {{ trunc(title, 20) }}' 2>/dev/null)
    [ -n "$info" ] && printf '%s♫ %s  %s' "$ink" "$info" "$reset"
fi

printf '%s%s %s' "$dim" "$(date '+%Y-%m-%d %H:%M')" "$reset"
