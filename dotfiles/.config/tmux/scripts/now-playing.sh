#!/bin/sh
# "now playing" content for the dracula custom: segment.
# Plain text (dracula styles it); empty while nothing is actively Playing
# so @dracula-show-empty-plugins hides the segment entirely.

command -v playerctl >/dev/null 2>&1 || exit 0
[ "$(playerctl status 2>/dev/null)" = "Playing" ] || exit 0

info=$(playerctl metadata --format '{{ trunc(artist, 12) }} — {{ trunc(title, 20) }}' 2>/dev/null)
[ -n "$info" ] || exit 0

printf '\xe2\x99\xab %s' "$info"
