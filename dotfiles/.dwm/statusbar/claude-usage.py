#!/usr/bin/env python3
"""Claude usage chip for the dwm status bar: "✦ CS 54% · PH 94%" (work and personal account).

Each number is the worse of the 5 hour and weekly window. The popup with the details is the
Claude tab of dwm-popup.py. The data is the cache of claude-usage-collect, no network here.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from popup import claude_data as cd  # noqa: E402

# status bar chip escapes of dwm: grey, yellow, orange, red
BADGE_GREY, BADGE_YELLOW, BADGE_ORANGE, BADGE_RED = "\x0e", "\x02", "\x03", "\x05"
CLICK_BYTE = "\x14"  # statuscmd byte 20, handled in click.sh
ICON = "\uf0e7"  # Nerd Font bolt, the icon of the Claude tab


def bar():
    parts, worst = [], None
    for profile, label, _name, _accent in cd.PROFILES:
        data = cd.load(profile)
        if not data:
            continue
        w = cd.summarize(data)
        pct = max(w["session"]["pct"], w["week"]["pct"])
        parts.append(f"{label} {round(pct)}%")
        if cd.health(data)[0]:  # the chip colour follows the accounts with live data
            worst = pct if worst is None else max(worst, pct)
    if not parts:
        return
    badge = BADGE_GREY
    if worst is not None:
        badge = BADGE_RED if worst >= 95 else BADGE_ORANGE if worst >= 80 else BADGE_YELLOW if worst >= 60 else BADGE_GREY
    sys.stdout.write(f"{CLICK_BYTE}{badge} {ICON} {' \u00b7 '.join(parts)} \x01 ")


if __name__ == "__main__":
    if sys.argv[1:] == ["bar"]:
        bar()
    else:
        sys.exit(__doc__)
