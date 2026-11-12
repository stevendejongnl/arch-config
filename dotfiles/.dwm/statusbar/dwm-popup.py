#!/usr/bin/env python3
"""The popup of the dwm status bar: one window that shows Case, Claude, Calendar, Keito or Notifications. The chips in the bar
are the tabs (the chip of the shown one is cyan), so the window has no tab strip of its own.

  dwm-popup.py [case|claude|calendar|keito|notifications]   open on that tab (click.sh runs this). When the popup is
                                         already open, the same tab closes it and another tab switches.
  dwm-popup.py <tab> --at X Y            open under that point (click.sh passes the position of the click)
  dwm-popup.py png DIR [tab ...]         render the tabs to PNG files, for checking the layout
"""
import fcntl
import os
import signal
import subprocess
import sys
import time
import warnings
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
warnings.filterwarnings("ignore", category=DeprecationWarning)

from popup.theme import Gdk, GLib, Gtk, install_css, label, margins  # noqa: E402
from popup.calendar_panel import CalendarPanel  # noqa: E402
from popup.case_panel import CasePanel  # noqa: E402
from popup.claude_panel import ClaudePanel  # noqa: E402
from popup.keito_panel import KeitoPanel  # noqa: E402
from popup.notifications_panel import NotificationsPanel  # noqa: E402

PANELS = [CasePanel, ClaudePanel, CalendarPanel, KeitoPanel, NotificationsPanel]  # the order of the chips in the bar
PANEL_WIDTH, PANEL_HEIGHT = 662, 440
BAR_HEIGHT = 36  # clicks in this band at the top of the monitor are clicks on the bar
RUN_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))


class Popup:
    def __init__(self, first_tab):
        install_css()
        # a classic scrollbar would widen the window once content scrolls, and dwm sees a window that grows
        Gtk.Settings.get_default().set_property("gtk-overlay-scrolling", True)
        self.panels = [cls() for cls in PANELS if cls.available()]
        self.current = None

        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        margins(body, 18, 18, 18, 18)

        self.stack = Gtk.Stack()
        self.stack.set_homogeneous(True)
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(120)
        for panel in self.panels:
            scroller = Gtk.ScrolledWindow()
            scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)  # NEVER would pass the content width up
            scroller.set_overlay_scrolling(True)
            # a fixed size: the window never resizes after it opened, so dwm has nothing to move
            scroller.set_min_content_width(PANEL_WIDTH)
            scroller.set_max_content_width(PANEL_WIDTH)
            scroller.set_min_content_height(PANEL_HEIGHT)
            scroller.set_max_content_height(PANEL_HEIGHT)
            scroller.set_propagate_natural_width(False)
            scroller.set_propagate_natural_height(False)
            scroller.add(panel)
            self.stack.add_named(scroller, panel.name)
        body.pack_start(self.stack, False, False, 0)
        self.body = body

        names = [p.name for p in self.panels]
        self.select(first_tab if first_tab in names else (names[0] if names else None))
        self.tick(0)

    def select(self, name):
        if name is None:
            return
        self.current = name
        for panel in self.panels:
            panel.visible = panel.name == name  # a panel may only count as seen while it is shown
        self.stack.set_visible_child_name(name)
        write_state(name)

    def tick(self, seconds):
        for panel in self.panels:
            panel.tick(seconds)
        return True


def write_state(name):
    try:
        (RUN_DIR / "dwm-popup-tab").write_text(name or "")
    except OSError:
        pass


def request_running_popup(tab):
    """Ask the open popup to switch to the tab, or close when it shows that tab. True when one is open."""
    lock = open(RUN_DIR / "dwm-popup.lock", "a+")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        lock.seek(0)
        try:
            (RUN_DIR / "dwm-popup.request").write_text(tab)
            os.kill(int(lock.read().strip()), signal.SIGUSR1)
        except (OSError, ValueError):
            pass
        return None
    lock.seek(0)
    lock.truncate()
    lock.write(str(os.getpid()))
    lock.flush()
    return lock  # keep the lock while we run


def focused_point(display):
    """The centre of the focused window, so a key press opens the popup on the monitor you work on.
    Falls back to the pointer."""
    try:
        out = subprocess.run(["xdotool", "getactivewindow", "getwindowgeometry", "--shell"],
                             capture_output=True, text=True, timeout=2, check=True).stdout
        v = dict(line.split("=") for line in out.split())
        return int(v["X"]) + int(v["WIDTH"]) // 2, int(v["Y"]) + int(v["HEIGHT"]) // 2
    except (OSError, subprocess.SubprocessError, ValueError, KeyError):
        return tuple(display.get_default_seat().get_pointer().get_position()[1:])


def show(tab, at=None):
    lock = request_running_popup(tab)
    if lock is None:
        return
    popup = Popup(tab)
    body = popup.body

    win = Gtk.Window()
    win.set_wmclass("claude-git-guard", "claude-git-guard")  # dwm floats this class
    win.set_title("Status bar")
    win.set_decorated(False)
    win.set_resizable(False)
    win.set_skip_taskbar_hint(True)
    win.set_keep_above(True)
    win.add(body)

    # Open directly below the bar, centred under the click. The position is set before the
    # window is mapped: dwm takes that as absolute, but adds the monitor origin to a later move.
    display = Gdk.Display.get_default()
    body.show_all()  # a hidden widget reports a width of 0
    width = body.get_preferred_width()[1]
    if at:
        # a click on a chip: centred under the click
        geo = display.get_monitor_at_point(*at).get_geometry()
        x = at[0] - width // 2
    else:
        # a key (Mod+n): always the same place, under the right end of the bar where the chips are,
        # on the monitor of the focused window
        geo = display.get_monitor_at_point(*focused_point(display)).get_geometry()
        x = geo.x + geo.width
    win.move(min(max(x, geo.x + 8), geo.x + geo.width - width - 8), geo.y)
    win.show_all()
    popup.select(popup.current)

    def close(*_):
        write_state("")
        Gtk.main_quit()
        return True

    def on_request(*_):
        try:
            wanted = (RUN_DIR / "dwm-popup.request").read_text().strip()
        except OSError:
            return True
        if wanted == popup.current:
            close()
        else:
            popup.select(wanted)
        return True

    def keep_open():
        """Close when the popup lost the focus and the pointer is away from it. A click on the bar takes
        the focus too, but that click switches tab or toggles, so the pointer in the bar keeps it open."""
        if win.is_active():
            return True
        _s, x, y = display.get_default_seat().get_pointer().get_position()
        wx, wy = win.get_position()
        ww, wh = win.get_size()
        inside = wx <= x < wx + ww and wy <= y < wy + wh
        in_bar = geo.y <= y < geo.y + BAR_HEIGHT and geo.x <= x < geo.x + geo.width
        if not inside and not in_bar:
            close()
            return False
        return True

    def on_key(_w, event):
        names = [p.name for p in popup.panels]
        if event.keyval == Gdk.KEY_Escape:
            close()
        elif event.keyval in (Gdk.KEY_Right, Gdk.KEY_Left) and popup.current in names:
            step = 1 if event.keyval == Gdk.KEY_Right else -1
            popup.select(names[(names.index(popup.current) + step) % len(names)])
        elif Gdk.KEY_1 <= event.keyval < Gdk.KEY_1 + len(names):
            popup.select(names[event.keyval - Gdk.KEY_1])

    win.connect("key-press-event", on_key)
    win.connect("delete-event", close)
    GLib.timeout_add(700, lambda: GLib.timeout_add(250, keep_open) and False)  # not while dwm maps and focuses us
    GLib.timeout_add_seconds(1, popup.tick, 1)
    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGUSR1, on_request)
    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGTERM, close)
    Gtk.main()


def render(directory, tabs):
    """Write one PNG per tab. The data is loaded synchronously here."""
    popup = Popup(tabs[0] if tabs else "keito")
    for panel in popup.panels:
        data = panel.load()
        if data is not None:
            panel.apply(data)
    win = Gtk.OffscreenWindow()
    win.add(popup.body)
    win.show_all()
    for name in tabs or [p.name for p in popup.panels]:
        popup.select(name)
        popup.tick(0)
        for _ in range(8):
            while Gtk.events_pending():
                Gtk.main_iteration()
            time.sleep(0.05)
        win.get_pixbuf().savev(str(Path(directory) / f"popup-{name}.png"), "png", [], [])


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["png"] and len(args) >= 2:
        render(args[1], args[2:])
    else:
        position = None
        if "--at" in args:
            i = args.index("--at")
            position = (int(args[i + 1]), int(args[i + 2]))
            del args[i:i + 3]
        show(args[0] if args else "", position)
