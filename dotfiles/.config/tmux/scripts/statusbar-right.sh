#!/bin/sh
# Right side of the tmux status bar: "now playing" (only while Playing) + clock.
# Self-styled; wired as a single dracula custom: segment.

green='#[fg=#282a36,bg=#50fa7b,nobold,nounderscore,noitalics]'
purple='#[fg=#282a36,bg=#bd93f9,nobold,nounderscore,noitalics]'
reset='#[fg=default,bg=default]'

if command -v playerctl >/dev/null 2>&1 && [ "$(playerctl status 2>/dev/null)" = "Playing" ]; then
    info=$(playerctl metadata --format '{{ trunc(artist, 12) }} — {{ trunc(title, 20) }}' 2>/dev/null)
    [ -n "$info" ] && printf '%s \xe2\x99\xab %s %s' "$green" "$info" "$reset"
fi

printf '%s %s %s' "$purple" "$(date '+%Y-%m-%d %H:%M')" "$reset"
