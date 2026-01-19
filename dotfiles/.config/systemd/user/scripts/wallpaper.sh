#! /bin/bash

#!/bin/bash

WALLPAPERS_DIR="$HOME/Pictures/wallpapers"
LOG_FILE="$WALLPAPERS_DIR/log.txt"

echo "===== $(date) =====" >> "$LOG_FILE"
echo "Searching for wallpapers in: $WALLPAPERS_DIR" >> "$LOG_FILE"


function find_wallpapers {
    local dir="$1"
    local file
    shopt -s nullglob
    for file in "$dir"/*; do
        if [[ -d "$file" ]]; then
            find_wallpapers "$file"
        elif [[ -f "$file" && $file =~ \.(jpg|jpeg|png|gif)$ ]]; then
            echo "$file" >> "$LOG_FILE"
            wallpapers_list+=("$file")
        fi
    done
}

wallpapers_list=()
find_wallpapers "$WALLPAPERS_DIR"

if [[ $# -gt 0 && ($1 == "-s" || $1 == "--select") ]]; then
    if [[ ${#wallpapers_list[@]} -gt 0 ]]; then
        echo "Select a wallpaper:"
        for (( i=0; i<${#wallpapers_list[@]}; i++ )); do
            echo "$((i+1)). ${wallpapers_list[i]}"
        done
        read -p "Enter the number of the wallpaper: " choice
        if [[ $choice -ge 1 && $choice -le ${#wallpapers_list[@]} ]]; then
            SELECTED_WALLPAPER="${wallpapers_list[choice-1]}"
            echo "Selected wallpaper: $SELECTED_WALLPAPER" >> "$LOG_FILE"
            feh --bg-fill "$SELECTED_WALLPAPER"
            notify-send -i monitor 'Wallpaper' "changed to $SELECTED_WALLPAPER"
        else
            echo "Invalid choice." >> "$LOG_FILE"
        fi
    else
        echo "No wallpapers found in the specified folder." >> "$LOG_FILE"
    fi
else
    if [[ ${#wallpapers_list[@]} -gt 0 ]]; then
        RANDOM_INDEX=$((RANDOM % ${#wallpapers_list[@]}))
        RANDOM_WALLPAPER="${wallpapers_list[RANDOM_INDEX]}"
        echo "Selected wallpaper: $RANDOM_WALLPAPER" >> "$LOG_FILE"
        feh --bg-fill "$RANDOM_WALLPAPER"
        notify-send -i monitor 'Wallpaper' "changed to $RANDOM_WALLPAPER"
    else
        echo "No wallpapers found in the specified folder." >> "$LOG_FILE"
    fi
fi

echo "=====================" >> "$LOG_FILE"

