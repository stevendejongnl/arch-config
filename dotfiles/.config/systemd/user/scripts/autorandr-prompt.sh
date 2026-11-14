#!/bin/bash
# Runs instead of plain `autorandr --change` on monitor hotplug (see
# /etc/systemd/system/autorandr.service.d/override.conf).
#
# - Monitor unplugged / nothing external detected -> switch silently to laptop.
# - Monitor(s) plugged -> ask via rofi. One match: yes/no. Multiple: pick one.
# - Deny (Escape or "Laptop only") -> force laptop-only profile.
# - Lid closed -> no prompt (nobody can see the laptop screen), load the match.
set -euo pipefail

force=0
[[ "${1:-}" == "--force" ]] && force=1

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

lid_is_closed() {
    grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null
}

has_laptop_profile() {
    [[ -d "$HOME/.config/autorandr/laptop" ]]
}

load_laptop_if_present() {
    has_laptop_profile || return 0
    autorandr --load laptop
}

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

# Lid closed: the laptop screen is not visible, so a prompt there could never be answered.
# Load the matching external profile directly.
if lid_is_closed; then
    autorandr --load "${external[0]}"
    "$HOME/.local/share/wallpaper-picker/bin/wallpaper.sh" --display-changed
    exit 0
fi

# No laptop profile (desktop machine) and one external match: nothing to ask, load it.
if ! has_laptop_profile && [[ ${#external[@]} -eq 1 ]]; then
    autorandr --load "${external[0]}"
    "$HOME/.local/share/wallpaper-picker/bin/wallpaper.sh" --display-changed
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
load_laptop_if_present

choice=$(printf '%s\n' "${external[@]}" "Laptop only (deny)" \
    | rofi -dmenu -p "Monitor connected - use profile?")

if [[ -z "$choice" || "$choice" == "Laptop only (deny)" ]]; then
    load_laptop_if_present
else
    autorandr --load "$choice"
fi

notify-send "Display" "$(autorandr --current)"

# Profile chosen: let the wallpaper picker run if it is in events mode.
"$HOME/.local/share/wallpaper-picker/bin/wallpaper.sh" --display-changed
