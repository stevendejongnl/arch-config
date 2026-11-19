#!/bin/sh

# Network chips: wifi signal strength while on wifi, and the VPN that is connected (home or work).
# Reads /proc and /sys only, because the status bar runs this every second.
# Home VPN = WireGuard interface wg-home or wg-home2, work VPN = OpenVPN tun interface (see ~/.local/bin/vpn).

WIFI=$(printf '\xef\x87\xab')       # Nerd Font wifi (U+F1EB)
LOCK=$(printf '\xef\x80\xa3')       # Nerd Font lock (U+F023)
BADGE=$(printf '\x0e')              # grey chip
RESET=$(printf '\x01')

# wifi: first wireless interface that is up; link quality is out of 70
while read -r iface rest; do
    iface=${iface%:}
    [ -d "/sys/class/net/$iface/wireless" ] || continue
    [ "$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)" = up ] || continue
    quality=$(echo "$rest" | awk '{print int($2)}')
    percent=$((quality * 100 / 70))
    [ "$percent" -gt 100 ] && percent=100
    printf '%s %s %d%% %s ' "$BADGE" "$WIFI" "$percent" "$RESET"
    break
done <<WIRELESS
$(tail -n +3 /proc/net/wireless 2>/dev/null)
WIRELESS

# vpn
vpn=""
if [ -d /sys/class/net/wg-home ] || [ -d /sys/class/net/wg-home2 ]; then
    vpn=home
elif ls -d /sys/class/net/tun* >/dev/null 2>&1; then
    vpn=work
fi
[ -n "$vpn" ] && printf '%s %s %s %s ' "$BADGE" "$LOCK" "$vpn" "$RESET"
exit 0
