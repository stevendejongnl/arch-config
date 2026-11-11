#!/bin/sh

# Notification chip: a bell, and the number of notifications in the dunst history that were not seen
# yet. The popup (Notifications tab) writes the highest id it showed to $seen_file.
# Yellow chip while something is new, grey otherwise. A crossed bell while dunst is paused.

BELL=$(printf '\xef\x83\xb3')       # Nerd Font bell (U+F0F3)
BELL_OFF=$(printf '\xef\x87\xb6')   # Nerd Font bell-slash (U+F1F6)
CLICK=$(printf '\x15')              # statuscmd byte: click opens the Notifications tab (see click.sh)
BADGE_NEW=$(printf '\x02')          # yellow chip
BADGE_NONE=$(printf '\x0e')         # grey chip
RESET=$(printf '\x01')

seen_file="${XDG_RUNTIME_DIR:-/tmp}/dwm-notifications-seen"

command -v dunstctl >/dev/null 2>&1 || exit 0
seen=$(cat "$seen_file" 2>/dev/null)
seen=${seen:-0}

# ids start over when dunst restarts: a seen id above every id in the history is stale
new=$(dunstctl history 2>/dev/null | jq --argjson seen "$seen" '
    [.data[0][].id.data] as $ids
    | (if ($ids | max // 0) < $seen then 0 else $seen end) as $s
    | [$ids[] | select(. > $s)] | length' 2>/dev/null)
new=${new:-0}

icon=$BELL
[ "$(dunstctl is-paused 2>/dev/null)" = "true" ] && icon=$BELL_OFF

if [ "$new" -gt 0 ]; then
    printf '%s%s %s %d %s ' "$CLICK" "$BADGE_NEW" "$icon" "$new" "$RESET"
else
    printf '%s%s %s %s ' "$CLICK" "$BADGE_NONE" "$icon" "$RESET"
fi
