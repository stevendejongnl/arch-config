#!/usr/bin/env python3
"""Drive time from the office to home, with the trend over the last 15 minutes.

Reads the Waze travel-time sensor from Home Assistant and prints one dwm status chip.
Prints nothing unless Steven is in the work zone. Called by home-eta.sh, which caches the output.
"""
import json
import os
import sys
import urllib.request
from datetime import datetime, timedelta, timezone

DIR = os.path.join(os.path.expanduser("~"), ".dwm", "statusbar", "home-eta")
SENSORS = ["sensor.waze_travel_time_steven_work_home", "sensor.google_travel_time_steven_work_home"]
PERSON = "person.steven_de_jong"
WORK_STATE = "Work Steven"
WINDOW_MIN = 15  # compare against the reading about this long ago

CAR = ""  # Nerd Font car glyph
BADGE_GREEN, BADGE_YELLOW, BADGE_ORANGE, BADGE_GREY = "\x0d", "\x02", "\x03", "\x0e"
RESET = "\x01"


def load_env():
    env = {}
    with open(os.path.join(DIR, ".env")) as f:
        for line in f:
            key, _, value = line.strip().partition("=")
            if key:
                env[key] = value
    return env


def get(env, path):
    request = urllib.request.Request(
        env["HA_URL"] + path,
        # The reverse proxy in front of HA answers 403 to the default Python-urllib user agent
        headers={"Authorization": "Bearer " + env["HA_TOKEN"], "User-Agent": "dwm-home-eta"},
    )
    with urllib.request.urlopen(request, timeout=5) as response:
        return json.load(response)


def minutes(state):
    try:
        return float(state)
    except (TypeError, ValueError):
        return None


def change(env, sensor, now_min):
    """Minutes gained since about WINDOW_MIN ago, or None when the history does not reach back far enough."""
    start = (datetime.now(timezone.utc) - timedelta(minutes=WINDOW_MIN + 5)).strftime("%Y-%m-%dT%H:%M:%SZ")
    history = get(env, f"/api/history/period/{start}?filter_entity_id={sensor}&minimal_response&no_attributes")
    readings = [(datetime.fromisoformat(s["last_changed"]), minutes(s["state"])) for s in (history[0] if history else []) if "last_changed" in s]
    readings = [(t, v) for t, v in readings if v is not None]
    if not readings:
        return None
    target = datetime.now(timezone.utc) - timedelta(minutes=WINDOW_MIN)
    # The reading closest to 15 minutes ago; skip it when history does not reach back far enough
    t, value = min(readings, key=lambda r: abs((r[0] - target).total_seconds()))
    if abs((t - target).total_seconds()) <= 6 * 60 or t < target:
        return now_min - value
    return None


def main():
    env = load_env()
    if get(env, "/api/states/" + PERSON)["state"] != WORK_STATE:
        return
    # One entry per sensor that has a value; a sensor that is unknown or unavailable is left out
    now_mins = {s: m for s in SENSORS if (m := minutes(get(env, "/api/states/" + s)["state"])) is not None}
    if not now_mins:
        return

    # The trend is the mean change of the sensors that have enough history
    deltas = [d for s, m in now_mins.items() if (d := change(env, s, m)) is not None]
    delta = sum(deltas) / len(deltas) if deltas else None
    shown = "/".join(f"{m:.0f}" for m in now_mins.values())

    if delta is None:
        badge, trend = BADGE_GREY, ""
    elif delta >= 10:
        badge, trend = BADGE_ORANGE, f" ↑+{delta:.0f}"
    elif delta >= 5:
        badge, trend = BADGE_YELLOW, f" ↑+{delta:.0f}"
    elif delta <= -2:
        badge, trend = BADGE_GREEN, f" ↓{delta:.0f}"
    else:
        badge, trend = BADGE_GREEN, " →"
    sys.stdout.write(f"{badge} {CAR} {shown}m{trend} {RESET} ")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # A failed poll must not break the bar; the cache keeps the last good chip
        sys.exit(1)
