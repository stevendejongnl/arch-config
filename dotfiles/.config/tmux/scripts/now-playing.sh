#!/bin/sh
# Single-shot "now playing" segment for the tmux status bar.
# Prints a styled dracula segment while a player is actively Playing;
# prints nothing otherwise (no leftover bar, no scroll animation, no flicker).

command -v playerctl >/dev/null 2>&1 || exit 0
[ "$(playerctl status 2>/dev/null)" = "Playing" ] || exit 0

info=$(playerctl metadata --format '{{ trunc(artist, 12) }} — {{ trunc(title, 20) }}' 2>/dev/null)
[ -n "$info" ] || exit 0

printf '#[fg=#282a36,bg=#50fa7b,nobold,nounderscore,noitalics] \xe2\x99\xab %s #[default]' "$info"
