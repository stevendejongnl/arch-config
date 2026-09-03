#!/bin/bash
# Runs instead of plain `autorandr --change` on monitor hotplug (see
# /etc/systemd/system/autorandr.service.d/override.conf).
#
# - Monitor unplugged / nothing external detected -> switch silently to laptop.
# - Monitor(s) plugged -> ask via rofi. One match: yes/no. Multiple: pick one.
# - Deny (Escape or "Laptop only") -> force laptop-only profile.
set -euo pipefail

force=0
[[ "${1:-}" == "--force" ]] && force=1

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

mapfile -t detected < <(autorandr --detected)
current=$(autorandr --current | head -1)

external=()
for p in "${detected[@]}"; do
    [[ "$p" == "laptop" || "$p" == "default" ]] && continue
    external+=("$p")
done

# No external monitor detected (unplug, or lid event with nothing new) - no prompt needed.
if [[ ${#external[@]} -eq 0 ]]; then
    autorandr --change --default default
    exit 0
fi

# Already sitting on one of the currently-matching external profiles - don't re-prompt,
# unless manually invoked with --force (e.g. the "Change Display" launcher).
if [[ "$force" -eq 0 ]]; then
    for p in "${external[@]}"; do
        [[ "$p" == "$current" ]] && exit 0
    done
fi

# Force laptop-only immediately so nothing shows dual/extended while we ask.
autorandr --load laptop

choice=$(printf '%s\n' "${external[@]}" "Laptop only (deny)" \
    | rofi -dmenu -p "Monitor connected - use profile?")

if [[ -z "$choice" || "$choice" == "Laptop only (deny)" ]]; then
    autorandr --load laptop
else
    autorandr --load "$choice"
fi

notify-send "Display" "$(autorandr --current)"
