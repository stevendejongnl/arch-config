#!/bin/sh

# Claude usage badge: "CS 88%  PH 94%" (work and personal account).
# The numbers only change when the collector writes its cache (about once a minute),
# so the 1s status bar loop re-uses the last text for 20 seconds.

cache="${XDG_RUNTIME_DIR:-/tmp}/dwm-claude-usage"
now=$(date +%s)

if [ ! -f "$cache" ] || [ "$((now - $(stat -c %Y "$cache")))" -ge 20 ]; then
    tmp="$cache.$$"
    "$HOME/.dwm/statusbar/claude-usage.py" bar > "$tmp" && mv "$tmp" "$cache"
fi

cat "$cache"
