#!/bin/sh
# Click handler for the dwm status bar. dwm runs it as: click.sh <statuscmd byte> <button>
# The byte is the decimal value of the 0x10-0x1F marker before the clicked segment
# (17 = date, 18 = package updates, 19 = Keito timer, 20 = Claude usage, 21 = notifications, 22 = case colour dot).
# The date, Keito and Claude chips open the Calendar, Keito and Claude tab of one popup. Button 1 is a left click.

[ "$2" = 1 ] || exit 0

# Where the click was. The popup opens there, and starting it takes a moment, so read the pointer now.
eval "$(xdotool getmouselocation --shell 2>/dev/null)"
at="--at ${X:-0} ${Y:-0}"

case "$1" in
  17) ~/.dwm/statusbar/dwm-popup.py calendar $at ;;
  19) ~/.dwm/statusbar/dwm-popup.py keito $at ;;
  20) ~/.dwm/statusbar/dwm-popup.py claude $at ;;
  21) ~/.dwm/statusbar/dwm-popup.py notifications $at ;;
  22) ~/.dwm/statusbar/dwm-popup.py case $at ;;
esac
