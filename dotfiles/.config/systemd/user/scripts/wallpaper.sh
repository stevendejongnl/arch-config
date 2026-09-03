#!/bin/bash
#
# Wallpaper changer.
#   (no args)      fetch a new wallpaper from Wallhaven (random category from
#                   categories.conf), fall back to a random local one on any
#                   failure (offline, API down, empty result, etc.)
#   -s / --select   pick from your local wallpapers directory interactively
#   -l / --local    force a random local wallpaper, skip the online fetch

WALLPAPERS_DIR="$HOME/Pictures/wallpapers"
ONLINE_DIR="$WALLPAPERS_DIR/online"
LOG_FILE="$WALLPAPERS_DIR/log.txt"
CATEGORIES_FILE="$HOME/.config/wallpaper/categories.conf"
LOCK_FILE="$WALLPAPERS_DIR/.wallpaper.lock"
ONLINE_KEEP=20   # prune cached online wallpapers beyond this count

mkdir -p "$WALLPAPERS_DIR" "$ONLINE_DIR"

# Prevent overlapping runs (e.g. OnFailure retry racing the original run)
exec 9>"$LOCK_FILE"
flock -n 9 || { echo "$(date '+%Y-%m-%d %H:%M:%S') already running, skip" >> "$LOG_FILE"; exit 0; }

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"; }

set_wallpaper() {
    local file="$1"
    feh --bg-fill "$file"
    notify-send -i monitor 'Wallpaper' "changed to $(basename "$file")"
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

pick_random_local() {
    wallpapers_list=()
    find_local_wallpapers "$WALLPAPERS_DIR"
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

fetch_online_wallpaper() {
    command -v curl >/dev/null 2>&1 || { log "curl not found, skipping online fetch"; return 1; }
    command -v jq   >/dev/null 2>&1 || { log "jq not found, skipping online fetch"; return 1; }

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

    local idx url id
    idx=$((RANDOM % count))
    url=$(echo "$resp" | jq -r ".data[$idx].path")
    id=$(echo "$resp" | jq -r ".data[$idx].id")
    if [[ -z "$url" || "$url" == "null" ]]; then
        log "wallhaven: couldn't parse image url"
        return 1
    fi

    local dest="$ONLINE_DIR/${query}-${id}.jpg"
    if ! curl -s --max-time 30 -o "$dest" "$url"; then
        log "wallhaven: download failed for $url"
        rm -f "$dest"
        return 1
    fi
    if [[ ! -s "$dest" ]]; then
        log "wallhaven: downloaded file is empty"
        rm -f "$dest"
        return 1
    fi

    prune_online_cache
    echo "$dest"
}

select_local() {
    wallpapers_list=()
    find_local_wallpapers "$WALLPAPERS_DIR"
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

log "===== run ($*) ====="

case "${1:-}" in
    -s|--select)
        select_local
        ;;
    -l|--local)
        chosen=$(pick_random_local) && set_wallpaper "$chosen"
        ;;
    *)
        chosen=$(fetch_online_wallpaper)
        if [[ -n "$chosen" ]]; then
            set_wallpaper "$chosen"
        else
            log "online fetch failed, falling back to local"
            chosen=$(pick_random_local) && set_wallpaper "$chosen"
        fi
        ;;
esac
