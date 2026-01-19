#!/usr/bin/env bash

echo "Snapshot 1 (before):"
lsusb > /tmp/lsusb_before.txt
cat /tmp/lsusb_before.txt
read -p "Plug het USB-apparaat in en druk op Enter..."

echo "Snapshot 2 (after):"
lsusb > /tmp/lsusb_after.txt
cat /tmp/lsusb_after.txt

echo "Nieuw apparaat gevonden:"
diff /tmp/lsusb_before.txt /tmp/lsusb_after.txt | grep ">"
