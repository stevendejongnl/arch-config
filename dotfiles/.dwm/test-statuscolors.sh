#!/bin/bash

# Test script for statuscolors integration
# Run this after installing dwm to verify color codes work

echo "=== Statuscolors Integration Test ==="
echo ""

# Test 1: Basic color codes
echo "Test 1: Setting basic color codes in status bar..."
xsetroot -name "$(printf '\x08')Teal $(printf '\x09')Yellow $(printf '\x0A')Orange $(printf '\x0B')Red$(printf '\x01')"
echo "✓ Status set. You should see colors in the status bar."
echo ""

# Test 2: Battery simulation
echo "Test 2: Battery color simulation..."
xsetroot -name "$(printf '\x08')[  100% ]$(printf '\x01') $(printf '\x09')[  50% ]$(printf '\x01') $(printf '\x0B')[  10% ]$(printf '\x01')"
echo "✓ Battery colors set (green -> yellow -> red)."
echo ""

# Test 3: Date with teal color
echo "Test 3: Date with teal color..."
xsetroot -name "$(printf '\x08')[   $(date '+%F %T') ]$(printf '\x01')"
echo "✓ Date set with teal color."
echo ""

# Test 4: Combined real status output
echo "Test 4: Running actual slstatus script..."
if [ -f /home/stevendejong/.dwm/slstatus/slstatus.sh ]; then
    status=$(/home/stevendejong/.dwm/slstatus/slstatus.sh)
    echo "Status output: $status"
    xsetroot -name "$status"
    echo "✓ Real status applied to status bar."
else
    echo "✗ slstatus.sh not found"
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "Color mapping reference:"
echo "0x01 = Reset to default (SchemeStatusNorm)"
echo "0x07 = SchemeStatusNorm (light gray)"
echo "0x08 = SchemeStatusLow (teal #1B9AAA)"
echo "0x09 = SchemeStatusMedium (yellow #FFC43D)"
echo "0x0A = SchemeStatusHigh (orange #FF6B35)"
echo "0x0B = SchemeStatusCritical (red #EF476F)"
echo "0x0C = SchemeStatusSuccess (green #06D6A0)"
