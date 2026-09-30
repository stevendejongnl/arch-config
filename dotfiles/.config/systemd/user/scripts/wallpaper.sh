#!/bin/bash
#
# Wallpaper changer.
#   (no args)         fetch a new wallpaper from Wallhaven (random category
#                     from categories.conf), fall back to a random local one
#                     on any failure (offline, API down, empty result, etc.)
#   --gui             fetch candidates and show a GTK picker to choose/blacklist
#   --candidates N    fetch N candidates (skipping blacklisted ids), print one
#                     absolute path per line
#   --set FILE        apply FILE as the wallpaper (feh + notify + record it)
#   --blacklist FILE  blacklist FILE (by Wallhaven id, or by path if local)
#                     and delete it
#   --reapply         re-apply the last-set wallpaper, no fetch, no GUI
#   -s / --select     pick from your local wallpapers directory interactively
#   -l / --local      force a random local wallpaper, skip the online fetch
#
#   --interval VALUE  set the timer's auto-run interval (systemd time span,
#                     e.g. "1h", "90m", "6h") via a drop-in override; does
#                     not touch the tracked wallpaper.timer file
#   --timer-enable    turn automatic (timer-driven) runs on
#   --timer-disable   turn automatic runs off; manual invocation (this
#                     script, the alias, the .desktop launchers) still works
#   --timer-status    show whether the timer is enabled and its interval

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

WALLPAPERS_DIR="$HOME/Pictures/wallpapers"
ONLINE_DIR="$WALLPAPERS_DIR/online"
LOG_FILE="$WALLPAPERS_DIR/log.txt"
CATEGORIES_FILE="$HOME/.config/wallpaper/categories.conf"
BLACKLIST_FILE="$HOME/.config/wallpaper/blacklist.txt"
CURRENT_FILE="$HOME/.config/wallpaper/current"
LOCK_FILE="$WALLPAPERS_DIR/.wallpaper.lock"
TIMER_OVERRIDE_DIR="$HOME/.config/systemd/user/wallpaper.timer.d"
TIMER_OVERRIDE_FILE="$TIMER_OVERRIDE_DIR/override.conf"
ONLINE_KEEP=20    # prune cached online wallpapers beyond this count
LOG_KEEP_LINES=2000

mkdir -p "$WALLPAPERS_DIR" "$ONLINE_DIR" "$(dirname "$BLACKLIST_FILE")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"; }

trim_log() {
    [[ -f "$LOG_FILE" ]] || return 0
    local lines
    lines=$(wc -l < "$LOG_FILE")
    if (( lines > LOG_KEEP_LINES )); then
        tail -n "$LOG_KEEP_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}
trap trim_log EXIT

# Prevent overlapping top-level runs (e.g. OnFailure retry racing the
# original run). GUI callbacks (--set / --blacklist / --candidates invoked
# by wallpaper-gui.py while the parent --gui run is still alive) set
# WALLPAPER_SH_NOLOCK=1 so they don't deadlock against the lock their own
# parent process is holding.
if [[ -z "${WALLPAPER_SH_NOLOCK:-}" ]]; then
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log "already running, skip"; exit 0; }
fi

# --- blacklist helpers ------------------------------------------------------

# Key for a wallpaper file: the Wallhaven id for cached online downloads
# (filename pattern "<query>-<id>.jpg"), otherwise the absolute path.
key_for_file() {
    local file="$1" base
    if [[ "$file" == "$ONLINE_DIR"/* ]]; then
        base=$(basename "$file")
        if [[ "$base" =~ -([A-Za-z0-9]+)\.jpg$ ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    fi
    echo "$file"
}

is_blacklisted() {
    local key="$1" k
    [[ -f "$BLACKLIST_FILE" ]] || return 1
    while IFS= read -r k; do
        [[ "$k" == "$key" ]] && return 0
    done < <(grep -vE '^\s*(#|$)' "$BLACKLIST_FILE" | awk '{print $1}')
    return 1
}

blacklist_add() {
    local key="$1" label="${2:-}"
    is_blacklisted "$key" && return 0
    printf '%s    # %s %s\n' "$key" "$label" "$(date '+%Y-%m-%d')" >> "$BLACKLIST_FILE"
}

# --- core actions ------------------------------------------------------------

set_wallpaper() {
    local file="$1"
    feh --bg-fill "$file"
    touch "$file"
    echo "$file" > "$CURRENT_FILE"
    timeout 3 notify-send -i monitor 'Wallpaper' "changed to $(basename "$file")" || log "notify-send timed out/failed, skipping"
    log "set: $file"
}

find_local_wallpapers() {
    local dir="$1" file
    shopt -s nullglob
    for file in "$dir"/*; do
        if [[ -d "$file" ]]; then
            find_local_wallpapers "$file"
        elif [[ -f "$file" && $file =~ \.(jpg|jpeg|png|gif)$ ]]; then
            wallpapers_list+=("$file")
        fi
    done
}

# Populates wallpapers_list with all local wallpapers that are not blacklisted.
find_local_wallpapers_filtered() {
    wallpapers_list=()
    find_local_wallpapers "$WALLPAPERS_DIR"
    local filtered=() f
    for f in "${wallpapers_list[@]}"; do
        is_blacklisted "$(key_for_file "$f")" || filtered+=("$f")
    done
    wallpapers_list=("${filtered[@]}")
}

pick_random_local() {
    find_local_wallpapers_filtered
    if [[ ${#wallpapers_list[@]} -eq 0 ]]; then
        log "no local wallpapers found in $WALLPAPERS_DIR"
        return 1
    fi
    echo "${wallpapers_list[$((RANDOM % ${#wallpapers_list[@]}))]}"
}

prune_online_cache() {
    # Keep the newest $ONLINE_KEEP, delete the rest
    local files
    mapfile -t files < <(ls -1t "$ONLINE_DIR"/*.jpg 2>/dev/null)
    if [[ ${#files[@]} -gt $ONLINE_KEEP ]]; then
        for ((i = ONLINE_KEEP; i < ${#files[@]}; i++)); do
            rm -f "${files[$i]}"
        done
    fi
}

# Fetch one wallpaper for a given query, skipping any result whose Wallhaven
# id is blacklisted. Prints the absolute path on success.
fetch_online_for_query() {
    local query="$1"
    command -v curl >/dev/null 2>&1 || { log "curl not found, skipping online fetch"; return 1; }
    command -v jq   >/dev/null 2>&1 || { log "jq not found, skipping online fetch"; return 1; }

    log "fetching from Wallhaven, category: $query"
    local resp
    resp=$(curl -s --max-time 15 -G "https://wallhaven.cc/api/v1/search" \
        --data-urlencode "q=$query" \
        --data-urlencode "categories=111" \
        --data-urlencode "purity=100" \
        --data-urlencode "sorting=random")

    if [[ -z "$resp" ]]; then
        log "wallhaven: empty response"
        return 1
    fi

    local count
    count=$(echo "$resp" | jq '.data | length' 2>/dev/null)
    if [[ -z "$count" || "$count" -eq 0 ]]; then
        log "wallhaven: no results for '$query'"
        return 1
    fi

    local -a tried=()
    local attempts=0 max_attempts=$(( count < 10 ? count : 10 ))
    while (( attempts < max_attempts )); do
        local idx=$((RANDOM % count))
        if [[ " ${tried[*]:-} " == *" $idx "* ]]; then
            continue
        fi
        tried+=("$idx")
        ((attempts++))

        local url id
        url=$(echo "$resp" | jq -r ".data[$idx].path")
        id=$(echo "$resp" | jq -r ".data[$idx].id")
        [[ -z "$url" || "$url" == "null" ]] && continue

        if is_blacklisted "$id"; then
            log "wallhaven: skipping blacklisted id $id"
            continue
        fi

        local dest="$ONLINE_DIR/${query}-${id}.jpg"
        if [[ -f "$dest" ]]; then
            echo "$dest"
            return 0
        fi

        if ! curl -s --max-time 30 -o "$dest" "$url"; then
            log "wallhaven: download failed for $url"
            rm -f "$dest"
            continue
        fi
        if [[ ! -s "$dest" ]]; then
            log "wallhaven: downloaded file is empty"
            rm -f "$dest"
            continue
        fi

        prune_online_cache
        echo "$dest"
        return 0
    done

    log "wallhaven: no non-blacklisted results for '$query'"
    return 1
}

fetch_online_wallpaper() {
    if [[ ! -f "$CATEGORIES_FILE" ]]; then
        log "no categories file at $CATEGORIES_FILE, skipping online fetch"
        return 1
    fi
    local categories
    mapfile -t categories < <(grep -vE '^\s*(#|$)' "$CATEGORIES_FILE")
    if [[ ${#categories[@]} -eq 0 ]]; then
        log "categories file is empty, skipping online fetch"
        return 1
    fi
    local query="${categories[$((RANDOM % ${#categories[@]}))]}"
    fetch_online_for_query "$query"
}

# Fetch N distinct candidate wallpapers, print one absolute path per line.
fetch_candidates() {
    local n="$1"
    command -v curl >/dev/null 2>&1 || { log "curl not found, skipping candidates fetch"; return 1; }
    command -v jq   >/dev/null 2>&1 || { log "jq not found, skipping candidates fetch"; return 1; }
    if [[ ! -f "$CATEGORIES_FILE" ]]; then
        log "no categories file at $CATEGORIES_FILE, skipping candidates fetch"
        return 1
    fi

    local categories
    mapfile -t categories < <(grep -vE '^\s*(#|$)' "$CATEGORIES_FILE")
    if [[ ${#categories[@]} -eq 0 ]]; then
        log "categories file is empty, skipping candidates fetch"
        return 1
    fi

    local -a results=()
    local tries=0 max_tries=$(( n * 4 > 12 ? n * 4 : 12 ))
    while (( ${#results[@]} < n && tries < max_tries )); do
        ((tries++))
        local q="${categories[$((RANDOM % ${#categories[@]}))]}"
        local path
        path=$(fetch_online_for_query "$q") || continue
        [[ -n "$path" ]] && results+=("$path")
    done

    if [[ ${#results[@]} -eq 0 ]]; then
        log "candidates: no results after $tries attempt(s)"
        return 1
    fi

    printf '%s\n' "${results[@]}"
}

select_local() {
    find_local_wallpapers_filtered
    if [[ ${#wallpapers_list[@]} -eq 0 ]]; then
        log "no local wallpapers found"
        exit 1
    fi
    echo "Select a wallpaper:"
    local i
    for (( i=0; i<${#wallpapers_list[@]}; i++ )); do
        echo "$((i+1)). ${wallpapers_list[i]}"
    done
    read -r -p "Enter the number of the wallpaper: " choice
    if [[ $choice -ge 1 && $choice -le ${#wallpapers_list[@]} ]]; then
        set_wallpaper "${wallpapers_list[choice-1]}"
    else
        log "invalid selection: $choice"
        exit 1
    fi
}

# --- new subcommands ---------------------------------------------------------

cmd_set() {
    local file="$1"
    if [[ -z "$file" || ! -f "$file" ]]; then
        log "--set: file not found: $file"
        exit 1
    fi
    set_wallpaper "$file"
}

cmd_blacklist() {
    local file="$1"
    if [[ -z "$file" ]]; then
        log "--blacklist: no file given"
        exit 1
    fi
    local key
    key=$(key_for_file "$file")
    blacklist_add "$key" "$(basename "$file")"
    rm -f "$file"
    log "blacklisted: $file (key=$key)"
}

cmd_reapply() {
    if [[ ! -f "$CURRENT_FILE" ]]; then
        log "--reapply: no current wallpaper recorded"
        exit 1
    fi
    local file
    file=$(<"$CURRENT_FILE")
    if [[ ! -f "$file" ]]; then
        log "--reapply: recorded wallpaper missing: $file"
        exit 1
    fi
    feh --bg-fill "$file"
    log "reapplied: $file"
}

# Fallback path shared by cmd_gui and the default no-args case.
fallback_fetch_or_local() {
    local chosen
    chosen=$(fetch_online_wallpaper)
    if [[ -n "$chosen" ]]; then
        set_wallpaper "$chosen"
    else
        log "online fetch failed, falling back to local"
        chosen=$(pick_random_local) && set_wallpaper "$chosen"
    fi
}

cmd_gui() {
    if ! command -v python3 >/dev/null 2>&1; then
        log "python3 not found, falling back to non-interactive pick"
        fallback_fetch_or_local
        return
    fi

    local rc
    WALLPAPER_SH_NOLOCK=1 python3 "$SCRIPT_DIR/wallpaper-gui.py" "$SCRIPT_PATH"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        log "gui exited non-zero ($rc), falling back to non-interactive pick"
        fallback_fetch_or_local
    fi
}

# --- timer control -------------------------------------------------------------
# These manage wallpaper.timer only. wallpaper.service (and therefore --gui,
# manual runs, the alias, and the .desktop launchers) is untouched either way
# -- disabling the timer only stops the automatic every-N-hours run.

cmd_set_interval() {
    local value="$1"
    if [[ -z "$value" ]]; then
        echo "usage: wallpaper.sh --interval <systemd time span, e.g. 1h, 90m, 6h>" >&2
        exit 1
    fi
    mkdir -p "$TIMER_OVERRIDE_DIR"
    # Blank OnUnitActiveSec first: systemd drop-ins accumulate values for
    # list-type directives rather than replacing them.
    printf '[Timer]\nOnUnitActiveSec=\nOnUnitActiveSec=%s\n' "$value" > "$TIMER_OVERRIDE_FILE"
    systemctl --user daemon-reload
    log "timer interval set to $value"
    echo "interval set to $value"
}

cmd_timer_enable() {
    systemctl --user enable --now wallpaper.timer
    log "timer enabled"
    echo "timer enabled: wallpaper runs automatically again"
}

cmd_timer_disable() {
    systemctl --user disable --now wallpaper.timer
    log "timer disabled"
    echo "timer disabled: wallpaper only changes when you run it manually"
}

cmd_timer_status() {
    local enabled interval
    enabled=$(systemctl --user is-enabled wallpaper.timer 2>/dev/null)
    [[ -z "$enabled" ]] && enabled="unknown"
    interval="3h (default, from wallpaper.timer)"
    if [[ -f "$TIMER_OVERRIDE_FILE" ]]; then
        interval="$(grep -oP '(?<=OnUnitActiveSec=).+' "$TIMER_OVERRIDE_FILE" | tail -1) (override)"
    fi
    echo "timer: $enabled"
    echo "interval: $interval"
    systemctl --user list-timers wallpaper.timer --no-pager 2>/dev/null
}

# --- dispatch -----------------------------------------------------------------

log "===== run ($*) ====="

case "${1:-}" in
    -s|--select)
        select_local
        ;;
    -l|--local)
        chosen=$(pick_random_local) && set_wallpaper "$chosen"
        ;;
    --candidates)
        fetch_candidates "${2:-3}"
        ;;
    --set)
        cmd_set "$2"
        ;;
    --blacklist)
        cmd_blacklist "$2"
        ;;
    --reapply)
        cmd_reapply
        ;;
    --gui)
        cmd_gui
        ;;
    --interval)
        cmd_set_interval "$2"
        ;;
    --timer-enable)
        cmd_timer_enable
        ;;
    --timer-disable)
        cmd_timer_disable
        ;;
    --timer-status)
        cmd_timer_status
        ;;
    *)
        fallback_fetch_or_local
        ;;
esac
