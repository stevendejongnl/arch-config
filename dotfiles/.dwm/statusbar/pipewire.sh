#!/bin/sh

getDefaultSink() {
    defaultSink=$(pactl info | awk -F : '/Default Sink:/{print $2}')
    description=$(pactl list sinks | sed -n "/${defaultSink}/,/Description/s/^\s*Description: \(.*\)/\1/p")

    if [[ $description == *"Family 17h/19h"* || $description == *"Starship/Matisse"* ]]; then
        echo "Speakers"
    elif [[ $description == *"Navi 21/23"* || $description == *"Renoir Radeon"* ]]; then
        echo "Speakers HDMI"
    elif [[ $description == *"airpods"* ]]; then
        echo "AirPods"
    elif [[ $description == *"MDR-XB950N1"* ]]; then
        echo "Headphone"
    else
        echo "${description}"
    fi
}

getDefaultSource() {
    defaultSource=$(pactl info | awk -F : '/Default Source:/{print $2}')
    description=$(pactl list sources | sed -n "/${defaultSource}/,/Description/s/^\s*Description: \(.*\)/\1/p")
    echo "${description}"
}

# VOLUME=$(pamixer --get-volume)
VOLUME_HUMAN=$(pamixer --get-volume-human)
MUTED=$(pamixer --get-mute)
SINK=$(getDefaultSink)
# SOURCE=$(getDefaultSource)

VOLUME_INFO="${VOLUME_HUMAN} - ${SINK}"

# if [[ $VOLUME -gt 33 && $VOLUME -lt 66 ]]; then
    # VOLUME_INFO=" ${VOLUME_HUMAN}"
# elif [[ $VOLUME -gt 66 ]]; then
    # VOLUME_INFO="  ${VOLUME_HUMAN}"
# fi

if [[ $MUTED == "true" ]]; then
    VOLUME_INFO=" ${SINK}"
fi

case $1 in
    "--up")
        pamixer --increase 5
        ;;
    "--down")
        pamixer --decrease 5
        ;;
    "--mute")
        pamixer --toggle-mute
        ;;
    *)
        echo "[ ${VOLUME_INFO} ]"
        ;;
esac
