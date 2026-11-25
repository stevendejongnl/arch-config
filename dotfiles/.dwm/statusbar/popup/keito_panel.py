"""Keito tab: logged time against the day goal as a bar per project, the running timer and today's entries."""
import json
import os
import urllib.request
import zlib
from datetime import date, datetime, timezone
from pathlib import Path

from gi.repository import Gtk

from .browser import open_work
from .theme import (DIM, GREEN, MARKUP, MUTED, ORANGE, PURPLE, RED, TEAL, YELLOW, Segments, button, clear, label,
                    margins, run_async)

KEITO_DIR = Path.home() / ".dwm" / "statusbar" / "keito"
API = "https://app.keito.ai/api/v2"
APP_URL = "https://app.keito.ai"
GOAL_HOURS = 8  # daily target; 0 hides it
REFRESH_SECONDS = 30
PALETTE = [TEAL, PURPLE, ORANGE, YELLOW, GREEN]
PROJECT_COLORS = {"Internal hours": PURPLE, "Retainer": TEAL}


def load_env():
    env = {}
    with open(KEITO_DIR / ".env") as f:
        for line in f:
            key, sep, value = line.strip().partition("=")
            if sep and not key.startswith("#"):
                env[key.removeprefix("export ").strip()] = value.strip().strip("'\"")
    return env


def call(path, method="GET"):
    env = load_env()
    req = urllib.request.Request(
        f"{API}/{path}", method=method,
        headers={"Authorization": f"Bearer {env['KEITO_API_KEY']}", "Keito-Account-Id": env["KEITO_COMPANY_ID"]})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp)


def hm(seconds):
    minutes = int(seconds) // 60
    return f"{minutes // 60}:{minutes % 60:02d}"


def hms(seconds):
    seconds = int(seconds)
    return f"{seconds // 3600}:{seconds // 60 % 60:02d}:{seconds % 60:02d}"


def minutes_of(clock):
    """'11:05' to minutes since midnight, None when the entry has no start or end time."""
    if not clock or ":" not in clock:
        return None
    h, m = clock.split(":")[:2]
    return int(h) * 60 + int(m)


def project_color(name):
    return PROJECT_COLORS.get(name) or PALETTE[zlib.crc32(name.encode()) % len(PALETTE)]


def title_of(entry):
    return entry.get("notes") or entry["task"]["name"]


def elapsed(entry):
    started = datetime.fromisoformat(entry["timer_started_at"].replace("Z", "+00:00"))
    return entry["duration_seconds"] + (datetime.now(timezone.utc) - started).total_seconds()


def now_minutes():
    now = datetime.now()
    return now.hour * 60 + now.minute


class KeitoPanel(Gtk.Box):
    name = "keito"
    title = "Keito"

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.data = None
        self.busy = False
        self.since_refresh = 0
        self.running_elapsed = None  # label updated every second

        self.total = label("", "big")
        self.goal = label("", "bigmuted")
        self.caption = label("", "muted", 1.0, markup=True)
        head = Gtk.Box(spacing=8, valign=Gtk.Align.END)
        head.pack_start(self.total, False, False, 0)
        head.pack_start(self.goal, False, False, 0)
        head.pack_end(self.caption, False, False, 6)
        head.get_style_context().add_class("head")
        self.progress = Segments(6)
        self.legend = Gtk.Box(spacing=14)
        self.running_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.project_seconds = {}

        self.pack_start(head, False, False, 0)
        self.pack_start(margins(self.progress, 14, 0, 20, 20), False, False, 0)
        self.pack_start(margins(self.legend, 8, 14, 20, 20), False, False, 0)
        self.pack_start(self.running_box, False, False, 0)
        self.pack_start(self.list, False, False, 0)

    @staticmethod
    def available():
        return (KEITO_DIR / ".env").exists()

    # data ------------------------------------------------------------

    def load(self):
        today = date.today().isoformat()
        return call(f"time_entries?from={today}&to={today}&per_page=100")["time_entries"]

    def refresh_async(self):
        if self.busy:
            return
        self.busy = True
        self.since_refresh = 0

        def done(entries):
            self.busy = False
            self.apply(entries)

        run_async(self.load, done)

    def tick(self, seconds):
        self.since_refresh += seconds
        if self.data is None or self.since_refresh >= REFRESH_SECONDS:
            self.refresh_async()
        if self.running_elapsed is not None and self.data:
            running = next((e for e in self.data if e["is_running"]), None)
            if running:
                self.running_elapsed.set_text(hms(elapsed(running)))
                self.update_total()

    def logged_seconds(self):
        total = sum(e["duration_seconds"] for e in self.data)
        running = next((e for e in self.data if e["is_running"]), None)
        return total + (elapsed(running) - running["duration_seconds"] if running else 0)

    def hint(self):
        if not self.data:
            return ""
        running = next((e for e in self.data if e["is_running"]), None)
        return f"● {hm(elapsed(running))}" if running else hm(self.logged_seconds())

    # view ------------------------------------------------------------

    def update_total(self):
        logged = self.logged_seconds()
        self.total.set_text(hm(logged))
        if not GOAL_HOURS:
            return
        goal = GOAL_HOURS * 3600
        seconds = dict(self.project_seconds)
        running = next((e for e in self.data if e["is_running"]), None) if self.data else None
        if running:  # the running entry keeps growing between two refreshes
            name = running["project"]["name"]
            seconds[name] = seconds.get(name, 0) + elapsed(running) - running["duration_seconds"]
        self.progress.set([(secs / goal, project_color(name)) for name, secs in seconds.items()])
        if logged >= goal:
            self.caption.set_markup(MARKUP.format(c=GREEN, t="Goal reached"))
        else:
            self.caption.set_markup(MARKUP.format(c=MUTED, t=f"{hm(goal - logged)} to go"))

    def apply(self, entries):
        if entries is None:
            if self.data is None:
                clear(self.list)
                self.list.pack_start(label("Could not reach Keito.", "muted"), False, False, 0)
                self.list.show_all()
            return
        self.data = entries
        self.goal.set_text(f" / {GOAL_HOURS}:00" if GOAL_HOURS else "")
        self.update_total()
        if not GOAL_HOURS:
            self.progress.hide()

        running = next((e for e in entries if e["is_running"]), None)
        self.project_seconds = {}
        for e in entries:
            name = e["project"]["name"]
            self.project_seconds[name] = self.project_seconds.get(name, 0) + e["duration_seconds"]
        self.update_total()
        clear(self.legend)
        for name in self.project_seconds:
            self.legend.pack_start(label(f"<span foreground='{project_color(name)}'>●</span>  {name}", "muted",
                                         markup=True), False, False, 0)

        clear(self.running_box)
        self.running_elapsed = None
        if running:
            self.running_box.pack_start(self.running_row(running), False, False, 0)

        clear(self.list)
        done = sorted((e for e in entries if not e["is_running"]),
                      key=lambda e: minutes_of(e.get("started_time")) or 0, reverse=True)
        if done:
            self.list.pack_start(margins(label("TODAY", "section"), 14, 6, 20, 20), False, False, 0)
        for e in done:
            self.list.pack_start(self.entry_row(e), False, False, 0)
        if not entries:
            self.list.pack_start(margins(label("Nothing logged today.", "muted"), 14, 0, 20, 20), False, False, 0)
        self.show_all()
        self.progress.set_visible(bool(GOAL_HOURS))

    def row_frame(self, css):
        row = Gtk.Box(spacing=12)
        row.get_style_context().add_class(css)
        return row

    def running_row(self, e):
        row = self.row_frame("row")
        title = label(f"<span foreground='{GREEN}'>●</span>  {esc(short(title_of(e)))}", "rowname", markup=True,
                      ellipsize=True)
        title.set_valign(Gtk.Align.CENTER)
        self.running_elapsed = label(hms(elapsed(e)), "timer", 1.0)
        row.pack_start(title, True, True, 0)
        row.pack_end(button("Stop", "action-stop", lambda: self.act("stop", e["id"])), False, False, 0)
        row.pack_end(self.running_elapsed, False, False, 6)
        row.get_style_context().add_class("row-running")
        return row

    def entry_row(self, e):
        row = Gtk.Box(spacing=14)
        row.get_style_context().add_class("row-tight")
        length = label(hm(e["duration_seconds"]), "mono")
        length.set_size_request(58, -1)
        title = label(esc(short(title_of(e))), "rowname", markup=True, ellipsize=True)
        row.pack_start(length, False, False, 0)
        row.pack_start(title, True, True, 0)
        row.pack_end(label(e["project"]["name"], "muted", 1.0), False, False, 0)
        box = Gtk.EventBox()  # a click on the row starts the entry again
        box.add(row)
        box.connect("button-press-event", lambda _w, _ev: self.act("restart", e["id"]))
        return box

    # actions ---------------------------------------------------------

    def act(self, action, entry_id):
        def work():
            call(f"time_entries/{entry_id}/{action}", method="PATCH")
            try:
                os.remove(KEITO_DIR / "last-run")  # keito.sh polls again on its next run
            except FileNotFoundError:
                pass
            return self.load()

        run_async(work, self.apply)

    @staticmethod
    def open_url(url):
        open_work(url)


def short(text, limit=58):
    return text if len(text) <= limit else text[: limit - 1] + "…"


def esc(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
