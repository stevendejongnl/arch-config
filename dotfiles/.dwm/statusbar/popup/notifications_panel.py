"""Notifications tab: the history of dunst as cards grouped by day, with dismiss, clear all and do not disturb."""
import html
import json
import os
import re
import subprocess
import time
import zlib
from datetime import date, datetime, timedelta
from pathlib import Path

from gi.repository import GLib, Gtk, Pango

from .theme import (DIM, GREEN, MARKUP, MUTED, ORANGE, PURPLE, RED, TEAL, YELLOW, button, clear, label, margins,
                    rgb, run_async)

SEEN_FILE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "dwm-notifications-seen"
REFRESH_SECONDS = 2
PALETTE = [TEAL, PURPLE, ORANGE, YELLOW, GREEN, "#6BA6FF"]
TAG = re.compile(r"<[^>]+>")


def dunstctl(*args):
    return subprocess.run(["dunstctl", *args], capture_output=True, text=True, timeout=5, check=True).stdout


def read_seen():
    try:
        return int(SEEN_FILE.read_text())
    except (OSError, ValueError):
        return 0


def write_seen(value):
    try:
        SEEN_FILE.write_text(str(value))
    except OSError:
        pass


def plain(text):
    """dunst bodies carry markup (<b>, <a href>): show them as text."""
    return html.unescape(TAG.sub("", text or "")).strip()


def copy_text(text):
    """Own the X clipboard through xclip, which forks and keeps serving it after this popup closes."""
    subprocess.run(["xclip", "-selection", "clipboard", "-in"], input=text.encode(), timeout=5, check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def esc(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def wall_time(timestamp_us):
    """dunst stamps notifications in microseconds of CLOCK_BOOTTIME."""
    boot_now = time.clock_gettime(time.CLOCK_BOOTTIME)
    return datetime.fromtimestamp(time.time() - (boot_now - timestamp_us / 1e6))


def ago(when):
    seconds = (datetime.now() - when).total_seconds()
    if seconds < 60:
        return "now"
    if seconds < 3600:
        return f"{int(seconds // 60)}m"
    if when.date() == date.today():
        return f"{int(seconds // 3600)}h"
    return when.strftime("%H:%M")


def day_label(when):
    if when.date() == date.today():
        return "TODAY"
    if when.date() == date.today() - timedelta(days=1):
        return "YESTERDAY"
    return when.strftime("%A %-d %B").upper()


def app_color(app):
    return PALETTE[zlib.crc32(app.encode()) % len(PALETTE)]


class NotificationsPanel(Gtk.Box):
    name = "notifications"
    title = "Notifications"

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.items = None
        self.paused = False
        self.busy = False
        self.visible = False
        self.since_refresh = 0
        self.signature = None
        self.baseline = read_seen()  # notifications above this id were not seen before this popup opened

        self.heading = label("Notifications", "name")
        self.count = label("", "muted")
        titles = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        titles.pack_start(self.heading, False, False, 0)
        titles.pack_start(self.count, False, False, 0)
        self.dnd = button("", None, self.toggle_dnd)
        self.clear_all = button("Clear all", None, lambda: self.act("history-clear"))
        head = Gtk.Box(spacing=8)
        head.pack_start(titles, True, True, 0)
        head.pack_end(self.clear_all, False, False, 0)
        head.pack_end(self.dnd, False, False, 0)
        self.list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        for child, top in ((head, 2), (self.list, 16)):
            self.pack_start(margins(child, top), False, False, 0)

    @staticmethod
    def available():
        try:
            dunstctl("is-paused")
            return True
        except (OSError, subprocess.SubprocessError):
            return False

    # data ------------------------------------------------------------

    def load(self):
        history = json.loads(dunstctl("history"))["data"][0]
        items = [{
            "id": n["id"]["data"], "app": n["appname"]["data"] or "?", "summary": n["summary"]["data"],
            "body": n["body"]["data"], "urgency": n["urgency"]["data"], "when": wall_time(n["timestamp"]["data"]),
        } for n in history]
        return {"items": items, "paused": dunstctl("is-paused").strip() == "true"}

    def refresh_async(self):
        if self.busy:
            return
        self.busy = True
        self.since_refresh = 0

        def done(data):
            self.busy = False
            if data is not None:
                self.apply(data)

        run_async(self.load, done)

    def tick(self, seconds):
        self.since_refresh += seconds
        if self.items is None or self.since_refresh >= REFRESH_SECONDS:
            self.refresh_async()
        if self.visible and self.items:
            write_seen(max(n["id"] for n in self.items))

    def hint(self):
        new = [n for n in self.items or [] if n["id"] > self.baseline]
        return f"{len(new)} new" if new else ""

    # view ------------------------------------------------------------

    def apply(self, data):
        items, paused = data["items"], data["paused"]
        signature = (tuple(n["id"] for n in items), paused, int(time.time() // 60), self.baseline)
        self.items, self.paused = items, paused
        new = sum(1 for n in items if n["id"] > self.baseline)
        self.count.set_text(f"{len(items)} in history" + (f"  ·  {new} new" if new else ""))
        self.dnd.set_label("  Do not disturb: on" if paused else "  Do not disturb")
        style = self.dnd.get_style_context()
        style.add_class("action-warn") if paused else style.remove_class("action-warn")
        self.clear_all.set_sensitive(bool(items))
        if signature == self.signature:
            return
        self.signature = signature

        clear(self.list)
        if not items:
            self.list.pack_start(self.empty(), False, False, 0)
        day = None
        for n in sorted(items, key=lambda n: n["id"], reverse=True):
            if day_label(n["when"]) != day:
                day = day_label(n["when"])
                self.list.pack_start(margins(label(day, "section"), 4 if self.list.get_children() else 0),
                                     False, False, 0)
            self.list.pack_start(self.card(n), False, False, 0)
        self.list.show_all()

    def empty(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6, valign=Gtk.Align.CENTER)
        bell = label(f"<span size='36000' foreground='{MUTED}'></span>", None, 0.5, markup=True)
        box.pack_start(margins(bell, 70), False, False, 0)
        box.pack_start(label("You are all caught up", "rowtitle", 0.5), False, False, 0)
        box.pack_start(label("New notifications show up here.", "muted", 0.5), False, False, 0)
        return box

    def card(self, n):
        new = n["id"] > self.baseline
        row = Gtk.Box(spacing=12)
        row.get_style_context().add_class("row-crit" if n["urgency"] == "CRITICAL" else "row-soon" if new else "row")
        color = app_color(n["app"])

        tile = label(n["app"][:1].upper(), "apptile", 0.5)
        tile.set_valign(Gtk.Align.START)
        r, g, b = (round(c * 255) for c in rgb(color))
        provider = Gtk.CssProvider()
        provider.load_from_data(f"label {{ background: rgba({r},{g},{b},0.18); color: {color}; }}".encode())
        tile.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        top = Gtk.Box(spacing=8)
        top.pack_start(label(esc(n["app"].upper()), "app", markup=True), False, False, 0)
        top.pack_end(label(ago(n["when"]), "muted", 1.0), False, False, 0)
        summary = label(esc(plain(n["summary"]) or "(no title)"), "summary", markup=True)
        summary.set_ellipsize(Pango.EllipsizeMode.END)
        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text.pack_start(top, False, False, 0)
        text.pack_start(summary, False, False, 0)
        body = plain(n["body"])
        if body:
            lb = label(esc(body), "body", markup=True)
            lb.set_line_wrap(True)
            lb.set_lines(3)
            lb.set_ellipsize(Pango.EllipsizeMode.END)
            lb.set_max_width_chars(56)
            text.pack_start(lb, False, False, 0)

        dismiss = button("✕", "dismiss", lambda i=n["id"]: self.act("history-rm", str(i)))
        copy = button("\uf0c5", "dismiss", lambda: None)
        copy.connect("clicked", lambda b, n=n: self.copy(b, n))
        buttons = Gtk.Box(spacing=0, valign=Gtk.Align.START)
        for b in (copy, dismiss):
            b.get_style_context().remove_class("action")
            b.set_valign(Gtk.Align.START)
            buttons.pack_start(b, False, False, 0)
        row.pack_start(tile, False, False, 0)
        row.pack_start(text, True, True, 0)
        row.pack_end(buttons, False, False, 0)
        return row

    # actions ---------------------------------------------------------

    def copy(self, widget, n):
        """Copy the title and the text of one notification, and show a check mark for a moment."""
        copy_text("\n".join(t for t in (plain(n["summary"]), plain(n["body"])) if t))
        widget.set_label("\uf00c")
        GLib.timeout_add(1200, lambda: widget.set_label("\uf0c5") and False)

    def toggle_dnd(self):
        self.act("set-paused", "toggle")

    def act(self, *args):
        def work():
            dunstctl(*args)
            return self.load()

        self.busy = True

        def done(data):
            self.busy = False
            if data is not None:
                self.signature = None
                self.apply(data)

        run_async(work, done)
