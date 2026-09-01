#!/bin/sh

# Harvest running-timer indicator.
# Idle: dim clock glyph only. Running: green clock + elapsed H:MM.
# Polls the Harvest API at most once per $interval; every other invocation
# (the 1s statusbar loop) just re-renders from the cached state file.

CLOCK=$(printf '\xef\x80\x97')  # Nerd Font clock glyph (U+F017)

harvest_dir="$HOME/.dwm/statusbar/harvest"
env_file="$harvest_dir/.env"
state_file="$harvest_dir/state"
last_run_file="$harvest_dir/last-run"

interval=60

idle_output() {
    printf '%s%s%s  ' "$(printf '\x01')" "$CLOCK" "$(printf '\x01')"
}

[ -f "$env_file" ] || exit 0
. "$env_file"
[ -n "$HARVEST_ACCESS_TOKEN" ] && [ -n "$HARVEST_ACCOUNT_ID" ] || exit 0

current_time=$(date +%s)
if [ -f "$last_run_file" ]; then
    last_run=$(cat "$last_run_file")
else
    last_run=0
fi

if [ "$((current_time - last_run))" -ge "$interval" ]; then
    response=$(curl -s -m 5 \
        -H "Authorization: Bearer $HARVEST_ACCESS_TOKEN" \
        -H "Harvest-Account-Id: $HARVEST_ACCOUNT_ID" \
        -H "User-Agent: dwm-statusbar (steven@cloudsuite.com)" \
        "https://api.harvestapp.com/v2/time_entries?is_running=true")

    if [ -n "$response" ] && echo "$response" | jq -e . >/dev/null 2>&1; then
        hours=$(echo "$response" | jq -r '.time_entries[0].hours // empty')
        if [ -n "$hours" ]; then
            echo "running|$hours|$current_time" > "$state_file"
        else
            echo "idle||" > "$state_file"
        fi
        echo "$current_time" > "$last_run_file"
    fi
    # curl/parse failure: leave state_file and last_run_file untouched,
    # so we retry next second instead of flapping to idle.
fi

if [ -f "$state_file" ]; then
    IFS='|' read -r status hours fetched_at < "$state_file"
else
    status="idle"
fi

if [ "$status" = "running" ]; then
    elapsed_hours=$(awk -v h="$hours" -v f="$fetched_at" -v n="$current_time" \
        'BEGIN { print h + (n - f) / 3600 }')
    total_minutes=$(awk -v h="$elapsed_hours" 'BEGIN { printf "%d", h * 60 }')
    hh=$((total_minutes / 60))
    mm=$((total_minutes % 60))
    printf '%s%s%s %d:%02d %s  ' "$(printf '\x0C')" "$CLOCK" "$(printf '\x01')" "$hh" "$mm" "$(printf '\x01')"
else
    idle_output
fi
