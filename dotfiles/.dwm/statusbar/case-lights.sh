#!/bin/sh
# Exit 0 when this machine has case lights: the ASUS board (OpenRGB) or the Redragon mouse (USB 04d9:fc38).
# The status bar runs it every second, so it only reads sysfs. case_color.py and case_panel.py use the same check.

board_vendor=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null)
case "$board_vendor" in
  *ASUS*) exit 0 ;;
esac

for device in $(grep -sl -x 04d9 /sys/bus/usb/devices/*/idVendor); do
  [ "$(cat "${device%idVendor}idProduct" 2>/dev/null)" = fc38 ] && exit 0
done

exit 1
