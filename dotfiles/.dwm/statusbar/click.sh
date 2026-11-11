#!/bin/sh
# Click handler for the dwm status bar. dwm runs it as: click.sh <statuscmd byte> <button>
# The byte is the decimal value of the 0x10-0x1F marker before the clicked segment
# (17 = date, 18 = package updates, 19 = Keito timer). Button 1 is a left click.

[ "$2" = 1 ] || exit 0

case "$1" in
  17) xdg-open "https://calendar.google.com/calendar/r" ;;
  19) xdg-open "https://app.keito.ai" ;;
esac
