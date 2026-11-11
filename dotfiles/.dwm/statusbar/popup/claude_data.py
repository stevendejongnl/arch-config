"""Claude usage data: the cache of claude-usage-collect (systemd timer), the same file the Claude Code
status line reads. Nothing here calls the network, and nothing needs GTK, so the status bar can import it."""
import json
from datetime import datetime, timezone
from pathlib import Path

from .colors import DIM, GREEN, ORANGE, RED, TEAL, YELLOW

ACCOUNTS = Path.home() / ".claude" / "accounts"
# profile, short label, name, accent colour (the colours of the Claude Code status line badge)
PROFILES = [
    ("work", "CS", "CloudSuite", "#FF5C78"),
    ("personal", "PH", "Personal", "#3EE6E0"),
]
SESSION_SECONDS = 5 * 3600
WEEK_SECONDS = 7 * 86400


def level_color(pct):
    if pct >= 95:
        return RED
    if pct >= 80:
        return ORANGE
    if pct >= 60:
        return YELLOW
    return TEAL


def load(profile):
    try:
        return json.loads((ACCOUNTS / profile / "rate-limit-cache.json").read_text())
    except (OSError, ValueError):
        return None


def parse_time(iso):
    return datetime.fromisoformat(iso).astimezone() if iso else None


def window(pct, resets_at, length):
    """Usage of one window now. A window whose reset time is past has started over at 0%."""
    pct = float(pct or 0)
    reset = parse_time(resets_at)
    if reset is None:
        return {"pct": pct, "reset": None, "left": None, "pace": None, "passed": False}
    left = (reset - datetime.now(timezone.utc)).total_seconds()
    if left <= 0:
        return {"pct": 0.0, "reset": reset, "left": None, "pace": None, "passed": True}
    return {"pct": pct, "reset": reset, "left": left, "pace": min(max(1 - left / length, 0), 1), "passed": False}


def summarize(data):
    return {
        "session": window(data.get("session_pct", data.get("current_session")), data.get("session_resets_at"), SESSION_SECONDS),
        "week": window(data.get("weekly_pct", data.get("weekly")), data.get("weekly_resets_at"), WEEK_SECONDS),
    }


def age_seconds(data):
    fetched = parse_time(data.get("fetched_at"))
    return (datetime.now(timezone.utc) - fetched).total_seconds() if fetched else None


def fmt_span(seconds):
    minutes = int(seconds) // 60
    days, hours, minutes = minutes // 1440, minutes % 1440 // 60, minutes % 60
    if days:
        return f"{days}d {hours}h"
    if hours:
        return f"{hours}h {minutes}m"
    return f"{max(minutes, 1)}m"


def health(data):
    """(is live, colour, text) for the freshness of the data."""
    age = age_seconds(data)
    ago = f"{fmt_span(age)} ago" if age is not None and age >= 60 else "just now"
    status = data.get("data_status") or ("ok" if not data.get("stale") else "stale")
    if status == "ok":
        return True, GREEN, f"Live  ·  updated {ago}"
    text = {
        "token_expired": f"Token expired  ·  data from {ago}",
        "stale": f"Stale  ·  data from {ago}",
        "rate_limited": f"Rate limited  ·  data from {ago}",
        "error": f"Collector error  ·  data from {ago}",
    }.get(status, f"{status}  ·  data from {ago}")
    return False, (RED if status in ("token_expired", "stale") else YELLOW), text


