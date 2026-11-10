#!/bin/sh

# Tell dwm whether Spotify is playing, so tag 9 turns green.
# dwm reads this file on every status update. The file changes only when the state changes.

state_file="$HOME/.local/state/dwm-shared-tag-playing"

if [ "$(playerctl -p spotify status 2>/dev/null)" = "Playing" ]; then
    new_state="playing"
else
    new_state="stopped"
fi

[ "$(cat "$state_file" 2>/dev/null)" = "$new_state" ] && exit 0
mkdir -p "$(dirname "$state_file")"
echo "$new_state" > "$state_file"
