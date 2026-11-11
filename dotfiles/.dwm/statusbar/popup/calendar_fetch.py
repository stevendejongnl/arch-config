#!/usr/bin/env python3
"""Print today's events of the primary Google calendar as JSON (for the Calendar tab).

Needs the Google API libraries, so it runs through uv (see calendar_panel.py). It reuses the
OAuth token and the calendar code of the gcal skill.
"""
import importlib.util
import json
import re
from datetime import date, datetime, timedelta
from pathlib import Path

SKILL = Path.home() / ".claude" / "shared" / "skills" / "gcal" / "gcal-fetch.py"
# The same noise the gcal skill leaves out with --work-only
NOISE_TITLE = re.compile(r"Opvang Scott|Tandarts|Kapper|Auto garage|Fysio|lunch", re.IGNORECASE)
NOISE_ALL_DAY = re.compile(r"^(Kantoor|Home|Office|Thuis|Vrij)$|vrij|holiday|afwezig|out of office", re.IGNORECASE)


def meet_link(event):
    if event.get("hangoutLink"):
        return event["hangoutLink"]
    for point in event.get("conferenceData", {}).get("entryPoints", []):
        if point.get("entryPointType") == "video":
            return point.get("uri")
    location = event.get("location") or ""
    return location if location.startswith("http") else None


def main():
    spec = importlib.util.spec_from_file_location("gcal_fetch", SKILL)
    gcal = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gcal)

    start = datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0)
    events = gcal.fetch_events(gcal.authenticate(), start.isoformat(), (start + timedelta(days=1)).isoformat())

    out = []
    for e in events:
        title = (e.get("summary") or "(no title)").strip()
        me = next((a for a in e.get("attendees", []) if a.get("self")), {})
        all_day = "date" in e["start"]
        if e.get("status") == "cancelled" or me.get("responseStatus") == "declined" or NOISE_TITLE.search(title):
            continue
        if all_day:
            days = (date.fromisoformat(e["end"]["date"]) - date.fromisoformat(e["start"]["date"])).days
            if NOISE_ALL_DAY.search(title) or days > 2:  # office days, time off, long background items such as a quarter
                continue
        out.append({
            "id": e["id"],
            "title": title,
            "start": e["start"].get("dateTime") or e["start"]["date"],
            "end": e["end"].get("dateTime") or e["end"]["date"],
            "all_day": all_day,
            "meet": meet_link(e),
            "link": e.get("htmlLink"),
            "response": me.get("responseStatus"),
            "attendees": len(e.get("attendees", [])),
        })
    print(json.dumps(out))


if __name__ == "__main__":
    main()
