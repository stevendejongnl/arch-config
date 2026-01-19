#!/bin/bash
# Save as ~/. local/bin/fix-airpods-audio.sh

AIRPODS_SINK="bluez_output.60_93_16_3C_D3_B9.1"

# Set as default sink
pactl set-default-sink "$AIRPODS_SINK"

# Move all existing audio streams to AirPods
pactl list short sink-inputs | while read -r stream; do
    streamId=$(echo "$stream" | awk '{print $1}')
    pactl move-sink-input "$streamId" "$AIRPODS_SINK" 2>/dev/null
done

echo "All audio routed to AirPods"
