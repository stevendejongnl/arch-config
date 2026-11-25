#!/bin/sh

# Drive-time-home chip. Polls Home Assistant at most once per $interval through home-eta.py;
# every other invocation (the 1s statusbar loop) prints the cached chip.
# Prints nothing when Steven is not at the office, or when there is no .env.

dir="$HOME/.dwm/statusbar/home-eta"
cache="${XDG_RUNTIME_DIR:-/tmp}/dwm-home-eta"
interval=60

[ -f "$dir/.env" ] || exit 0

now=$(date +%s)
last=$(stat -c %Y "$cache" 2>/dev/null || echo 0)

if [ "$((now - last))" -ge "$interval" ]; then
    # Write to a temp file first: a failed poll keeps the old chip, an empty poll (not at work) clears it
    if out=$("$HOME/.dwm/statusbar/home-eta.py" 2>/dev/null); then
        printf '%s' "$out" > "$cache"
    else
        touch "$cache"
    fi
fi

cat "$cache" 2>/dev/null
