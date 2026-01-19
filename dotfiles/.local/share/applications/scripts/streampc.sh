#!/usr/bin/env bash
set -euo pipefail

# Wake streampc via network
echo "Sending WoL magic packet to streampc (DC:4A:3E:7A:DA:D0)..."
wakeonlan -i 192.168.1.255 DC:4A:3E:7A:DA:D0

pkill barriers &
sleep 2
barriers --daemon --disable-client-cert-checking -c ~/.local/share/barrier/.barrier.conf &
sleep 2
pkill scream &
sleep 2

# Start scream and wait for it to establish connection
scream -o pulse -i enp2s0 &
SCREAM_PID=$!

# Send a few UDP packets to wake up Windows Scream
for i in {1..5}; do
    # echo "HELLO" | nc -u -w1 192.168.1.53 4010 2>/dev/null || true
    echo "HELLO" | nc -u -w1 192.168.1.85 4010 2>/dev/null || true
    sleep 1
done

echo "Scream receiver started. Try playing audio on Windows now."
