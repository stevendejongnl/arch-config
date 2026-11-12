#!/usr/bin/env python3
"""Meeting alert: a floating popup in the middle of the screen from one minute before a meeting starts.

It stays until you dismiss it (the cross, Escape, or Join), or until the meeting ended. The Join button opens the
Google Meet link. An event without a video link gets no popup.

  meeting-alert.py            run as a service: reads the calendar, shows the popup when it is time
  meeting-alert.py test       show the popup once for a fake meeting, to check the look

The calendar comes from popup/calendar_fetch.py (the same code as the Calendar tab), through uv.
"""
import json
import subprocess
import sys
import warnings
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
warnings.filterwarnings("ignore", category=DeprecationWarning)

from popup.theme import Gdk, GLib, Gtk, button, install_css, label, margins, run_async  # noqa: E402
from popup.calendar_panel import uv_command  # noqa: E402

LEAD = timedelta(minutes=1)  # the popup appears this long before the start
FETCH_EVERY = 300  # seconds between two calendar reads
CHECK_EVERY = 5  # seconds between two checks of the clock


class Alert:
    def __init__(self, event, on_close):
        self.event = event
        self.on_close = on_close
        start = datetime.fromisoformat(event["start"])
        self.start = start

        win = Gtk.Window()
        win.set_wmclass("claude-git-guard", "claude-git-guard")  # dwm floats this class
        win.set_title("Meeting")
        win.set_decorated(False)
        win.set_resizable(False)
        win.set_skip_taskbar_hint(True)
        win.set_keep_above(True)
        win.get_style_context().add_class("meeting-alert")
        self.win = win

        overlay = Gtk.Overlay()
        overlay.add(self.build_body())
        cross = Gtk.Button(label="✕")  # the cross in the corner
        cross.get_style_context().add_class("dismiss")
        cross.set_relief(Gtk.ReliefStyle.NONE)
        cross.set_halign(Gtk.Align.END)
        cross.set_valign(Gtk.Align.START)
        margins(cross, top=8, end=8)
        cross.connect("clicked", lambda _b: self.close())
        overlay.add_overlay(cross)
        win.add(overlay)

        win.connect("key-press-event", lambda _w, e: e.keyval == Gdk.KEY_Escape and self.close())
        win.connect("delete-event", lambda *_: self.close() or True)

        # The position is set before the window is mapped: dwm takes that as absolute (see dwm-popup.py).
        overlay.show_all()
        width, height = overlay.get_preferred_width()[1], overlay.get_preferred_height()[1]
        display = Gdk.Display.get_default()
        pointer = display.get_default_seat().get_pointer().get_position()[1:]
        geo = display.get_monitor_at_point(*pointer).get_geometry()
        win.move(geo.x + (geo.width - width) // 2, geo.y + (geo.height - height) // 2)
        win.show_all()
        self.tick()
        self.timer = GLib.timeout_add_seconds(1, self.tick)

    def build_body(self):
        e = self.event
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.get_style_context().add_class("meeting-body")
        box.set_size_request(420, -1)
        margins(box, top=26, bottom=24, start=30, end=30)

        self.when = label("", "meeting-when", xalign=0.5)
        box.pack_start(self.when, False, False, 0)
        title = label(e["title"], "meeting-title", xalign=0.5, wrap=True)
        title.set_justify(Gtk.Justification.CENTER)
        box.pack_start(title, False, False, 0)

        end = datetime.fromisoformat(e["end"])
        detail = f"{self.start:%H:%M} – {end:%H:%M}"
        if e.get("attendees", 0) > 1:
            detail += f" · {e['attendees']} people"
        box.pack_start(label(detail, "dim", xalign=0.5), False, False, 0)

        url = e["meet"]
        join = button("Join Google Meet", "action-go", lambda: self.join(url))
        join.get_style_context().add_class("meeting-join")
        join.set_halign(Gtk.Align.CENTER)
        box.pack_start(margins(join, top=14), False, False, 0)
        return box

    def tick(self):
        seconds = int((self.start - datetime.now().astimezone()).total_seconds())
        if seconds > 0:
            text = f"STARTS IN {seconds // 60}:{seconds % 60:02d}"
        else:
            text = "STARTED" if seconds > -60 else f"STARTED {-seconds // 60} MIN AGO"
        self.when.set_text(text)
        return True

    def join(self, url):
        subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        self.close()

    def close(self):
        GLib.source_remove(self.timer)
        self.win.destroy()
        self.on_close()
        return True


class Service:
    def __init__(self):
        self.events = []
        self.dismissed = set()  # ids of the events whose popup was closed
        self.alert = None
        self.fetching = False

    def fetch(self):
        if not self.fetching:
            self.fetching = True

            def work():
                result = subprocess.run(uv_command(), capture_output=True, text=True, timeout=90, check=True)
                return json.loads(result.stdout.strip().splitlines()[-1])

            def done(events):
                self.fetching = False
                if events is not None:  # a failed read keeps the last list
                    self.events = events
                self.check()

            run_async(work, done)
        return True

    def check(self):
        if self.alert:
            return True
        now = datetime.now().astimezone()
        for e in self.events:
            if e["all_day"] or not e["meet"] or e["id"] in self.dismissed:
                continue
            start, end = datetime.fromisoformat(e["start"]), datetime.fromisoformat(e["end"])
            if start - LEAD <= now < end:
                self.show(e)
                break
        return True

    def show(self, event):
        def closed():
            self.dismissed.add(event["id"])
            self.alert = None
            self.check()  # a second meeting may be waiting

        self.alert = Alert(event, closed)

    def run(self):
        self.fetch()
        GLib.timeout_add_seconds(FETCH_EVERY, self.fetch)
        GLib.timeout_add_seconds(CHECK_EVERY, self.check)
        Gtk.main()


EXTRA_CSS = """
.meeting-alert { border: 1px solid {teal}; border-radius: 16px; }
.meeting-when { color: {teal}; font-size: 10pt; font-weight: 800; letter-spacing: 2px; }
.meeting-title { color: {text}; font-size: 20pt; font-weight: 800; }
.meeting-join { font-size: 12pt; padding: 9px 30px; }
"""


def install_extra_css():
    from popup.theme import TEAL, TEXT
    css = Gtk.CssProvider()
    css.load_from_data(EXTRA_CSS.replace("{teal}", TEAL).replace("{text}", TEXT).encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


def main():
    install_css()
    install_extra_css()
    if sys.argv[1:] == ["test"]:
        start = datetime.now().astimezone() + timedelta(seconds=45)
        fake = {"id": "test", "title": "Ordering standup", "all_day": False, "start": start.isoformat(),
                "end": (start + timedelta(minutes=15)).isoformat(), "attendees": 6,
                "meet": "https://meet.google.com/ban-owxf-yky", "link": None}
        Alert(fake, Gtk.main_quit)
        Gtk.main()
        return
    Service().run()


if __name__ == "__main__":
    main()
