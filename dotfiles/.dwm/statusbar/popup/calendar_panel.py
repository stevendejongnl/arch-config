"""Calendar tab: the meetings of today on a timeline and as a list, with a button to join the Google Meet."""
import json
import os
import shutil
import subprocess
import time
from datetime import datetime
from pathlib import Path

from gi.repository import Gtk

from .browser import open_work
from .theme import (DIM, GREEN, MARKUP, MUTED, TEAL, YELLOW, Timeline, button, clear, label, margins, run_async)

CREDENTIALS = Path.home() / ".config" / "gcalcli" / "credentials.json"
FETCH = Path(__file__).with_name("calendar_fetch.py")
CACHE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "dwm-calendar.json"
CALENDAR_URL = "https://calendar.google.com/calendar/r"
REFRESH_SECONDS = 120
SOON_MINUTES = 10  # a meeting this close to its start gets a highlighted Join button
RESPONSE_COLORS = {"accepted": TEAL, "tentative": YELLOW}


def uv_command():
    uv = shutil.which("uv") or str(Path.home() / ".local" / "bin" / "uv")
    return [uv, "run", "--quiet", "--with", "google-api-python-client", "--with", "google-auth-oauthlib",
            "--with", "google-auth-httplib2", "python3", str(FETCH)]


def fetch():
    result = subprocess.run(uv_command(), capture_output=True, text=True, timeout=90, check=True)
    events = json.loads(result.stdout.strip().splitlines()[-1])
    try:
        CACHE.write_text(json.dumps({"fetched": time.time(), "events": events}))
    except OSError:
        pass
    return events


def parse(iso):
    dt = datetime.fromisoformat(iso)
    return dt.astimezone() if dt.tzinfo else dt


def esc(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def left(seconds):
    minutes = max(int(seconds // 60), 1)
    return f"{minutes // 60}h {minutes % 60}m" if minutes >= 60 else f"{minutes}m"


class CalendarPanel(Gtk.Box):
    name = "calendar"
    title = "Calendar"

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.events = None
        self.busy = False
        self.since_refresh = 0
        self.since_render = 0

        self.heading = label(datetime.now().strftime("%A %-d %B"), "name")
        self.status = label("", "muted", 1.0, markup=True)
        head = Gtk.Box(spacing=8)
        head.pack_start(self.heading, False, False, 0)
        head.pack_end(self.status, False, False, 6)
        self.timeline = Timeline(64)
        self.all_day = Gtk.Box(spacing=8)
        self.list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        footer = Gtk.Box()
        footer.pack_end(button("Open Google Calendar  ↗", None, lambda: self.open_url(CALENDAR_URL)), False, False, 0)

        for child, top in ((head, 2), (self.timeline, 14), (self.all_day, 10), (self.list, 14), (footer, 14)):
            self.pack_start(margins(child, top), False, False, 0)

        try:
            cached = json.loads(CACHE.read_text())
            self.since_refresh = time.time() - cached["fetched"]
            self.apply(cached["events"])
        except (OSError, ValueError, KeyError):
            pass

    @staticmethod
    def available():
        return CREDENTIALS.exists()

    # data ------------------------------------------------------------

    def load(self):
        return fetch()

    def refresh_async(self):
        if self.busy:
            return
        self.busy = True
        self.since_refresh = 0

        def done(events):
            self.busy = False
            if events is None and self.events is None:
                clear(self.list)
                self.list.pack_start(label("Could not load the calendar.", "muted"), False, False, 0)
                self.list.show_all()
            elif events is not None:
                self.apply(events)

        run_async(self.load, done)

    def tick(self, seconds):
        self.since_refresh += seconds
        self.since_render += seconds
        if self.events is None and not self.busy or self.since_refresh >= REFRESH_SECONDS:
            self.refresh_async()
        if self.events is not None and self.since_render >= 20:
            self.apply(self.events)  # moves the now marker and the Join highlight

    def timed(self):
        return [e for e in self.events or [] if not e["all_day"]]

    def hint(self):
        now = datetime.now().astimezone()
        upcoming = [e for e in self.timed() if parse(e["end"]) > now]
        return f"{len(upcoming)} left" if self.events is not None else ""

    # view ------------------------------------------------------------

    def apply(self, events):
        self.events = events
        self.since_render = 0
        now = datetime.now().astimezone()
        now_min = now.hour * 60 + now.minute
        timed = self.timed()

        blocks = []
        for e in timed:
            s, f = parse(e["start"]), parse(e["end"])
            blocks.append((s.hour * 60 + s.minute, f.hour * 60 + f.minute, RESPONSE_COLORS.get(e["response"], DIM)))
        self.timeline.set(blocks, now=now_min, lo_hour=8, hi_hour=18)

        ongoing = next((e for e in timed if parse(e["start"]) <= now < parse(e["end"])), None)
        upcoming = next((e for e in timed if parse(e["start"]) > now), None)
        if ongoing:
            text = f"Now: {esc(ongoing['title'])}  ·  ends in {left((parse(ongoing['end']) - now).total_seconds())}"
            self.status.set_markup(MARKUP.format(c=GREEN, t=text))
        elif upcoming:
            text = f"Next: {esc(upcoming['title'])}  ·  in {left((parse(upcoming['start']) - now).total_seconds())}"
            self.status.set_markup(MARKUP.format(c=TEAL, t=text))
        else:
            self.status.set_markup(MARKUP.format(c=MUTED, t="No more meetings today"))

        clear(self.all_day)
        for e in (e for e in events if e["all_day"]):
            chip = label(f"◆  {esc(e['title'])}", "muted", markup=True)
            chip.get_style_context().add_class("plan")
            self.all_day.pack_start(chip, False, False, 0)

        clear(self.list)
        for e in timed:
            self.list.pack_start(self.row(e, now), False, False, 0)
        if not timed:
            self.list.pack_start(label("No meetings today.", "muted"), False, False, 0)
        self.show_all()
        self.all_day.set_visible(any(e["all_day"] for e in events))

    def row(self, e, now):
        start, end = parse(e["start"]), parse(e["end"])
        past = end <= now
        ongoing = start <= now < end
        soon = not ongoing and not past and (start - now).total_seconds() <= SOON_MINUTES * 60
        row = Gtk.Box(spacing=14)
        row.get_style_context().add_class("row-now" if ongoing else "row-soon" if soon else "row")

        when = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        when.set_size_request(58, -1)
        when.pack_start(label(start.strftime("%H:%M"), "time" if not past else "muted"), False, False, 0)
        when.pack_start(label(end.strftime("%H:%M"), "muted"), False, False, 0)

        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text.pack_start(label(esc(short(e["title"])), "dim" if past else "rowtitle", markup=True, ellipsize=True), False, False, 0)
        minutes = int((end - start).total_seconds() // 60)
        duration = f"{minutes // 60}h {minutes % 60:02d}m" if minutes >= 60 and minutes % 60 else \
            f"{minutes // 60}h" if minutes >= 60 else f"{minutes}m"
        parts = [duration]
        if e["attendees"] > 1:
            parts.append(f"{e['attendees']} people")
        if ongoing:
            parts.append(f"ends in {left((end - now).total_seconds())}")
        elif soon:
            parts.append(f"starts in {left((start - now).total_seconds())}")
        sub = "  ·  ".join(parts)
        if e["response"] == "tentative":
            sub += f"  ·  <span foreground='{YELLOW}'>tentative</span>"
        text.pack_start(label(sub, "muted", markup=True, ellipsize=True), False, False, 0)

        row.pack_start(when, False, False, 0)
        row.pack_start(text, True, True, 0)
        if e["meet"]:  # a past meeting keeps its link (a quiet button), to rejoin or to find the recording
            css = "action-go" if ongoing else "action-primary" if soon else None
            text_ = "▶  Join now" if ongoing else "↗  Meet link" if past else "▶  Join"
            row.pack_end(button(text_, css, lambda url=e["meet"]: self.open_url(url)), False, False, 0)
        return row

    @staticmethod
    def open_url(url):
        open_work(url)


def short(text, limit=52):
    return text if len(text) <= limit else text[: limit - 1] + "…"
