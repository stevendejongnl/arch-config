#!/bin/sh

# Keito running-timer badge.
# Idle: dim badge with clock glyph. Running: badge with clock + elapsed H:MM,
# green at first, yellow after 2h, orange after 4h so a forgotten timer stands out.
# Polls the Keito API at most once per $interval; every other invocation
# (the 1s statusbar loop) just re-renders from the cached start time.

CLOCK=$(printf '\xef\x80\x97')  # Nerd Font clock glyph (U+F017)
BADGE_ON=$(printf '\x0d')       # dark text on green background
BADGE_YELLOW=$(printf '\x02')  # dark text on yellow background
BADGE_ORANGE=$(printf '\x03')  # dark text on orange background
BADGE_OFF=$(printf '\x0e')      # light text on gray background
RESET=$(printf '\x01')
CLICK=$(printf '\x13')         # statuscmd byte: click opens the Keito tab of the popup (see click.sh)

keito_dir="$HOME/.dwm/statusbar/keito"
env_file="$keito_dir/.env"
state_file="$keito_dir/state"
last_run_file="$keito_dir/last-run"

interval=60

[ -f "$env_file" ] || exit 0
. "$env_file"
[ -n "$KEITO_API_KEY" ] && [ -n "$KEITO_COMPANY_ID" ] || exit 0

current_time=$(date +%s)
if [ -f "$last_run_file" ]; then
    last_run=$(cat "$last_run_file")
else
    last_run=0
fi

if [ "$((current_time - last_run))" -ge "$interval" ]; then
    response=$(curl -s -m 5 \
        -H "Authorization: Bearer $KEITO_API_KEY" \
        -H "Keito-Account-Id: $KEITO_COMPANY_ID" \
        "https://app.keito.ai/api/v2/time_entries?is_running=true")

    if [ -n "$response" ] && echo "$response" | jq -e '.time_entries' >/dev/null 2>&1; then
        started_at=$(echo "$response" | jq -r '.time_entries[0].timer_started_at // empty')
        if [ -n "$started_at" ]; then
            echo "running|$(date -d "$started_at" +%s)" > "$state_file"
        else
            echo "idle|" > "$state_file"
        fi
        echo "$current_time" > "$last_run_file"
    fi
    # curl/parse failure: leave state_file and last_run_file untouched,
    # so we retry next second instead of flapping to idle.
fi

status="idle"
[ -f "$state_file" ] && IFS='|' read -r status started_epoch < "$state_file"

if [ "$status" = "running" ] && [ -n "$started_epoch" ]; then
    total_minutes=$(( (current_time - started_epoch) / 60 ))
    badge=$BADGE_ON
    [ "$total_minutes" -ge 120 ] && badge=$BADGE_YELLOW
    [ "$total_minutes" -ge 240 ] && badge=$BADGE_ORANGE
    printf '%s%s %s %d:%02d %s  ' "$CLICK" "$badge" "$CLOCK" "$((total_minutes / 60))" "$((total_minutes % 60))" "$RESET"
else
    printf '%s%s %s %s  ' "$CLICK" "$BADGE_OFF" "$CLOCK" "$RESET"
fi
