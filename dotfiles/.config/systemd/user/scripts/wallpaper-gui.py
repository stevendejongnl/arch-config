#!/usr/bin/env python3
"""GTK3 wallpaper picker front end for wallpaper.sh.

Shows N candidate wallpapers, lets you blacklist the ones you don't like
(deleted + never offered again) and pick the one to apply, or shuffle for
N new candidates. Auto-dismisses after AUTO_DISMISS_SECONDS by applying the
first candidate, so an unattended timer run never hangs behind the window.

All fetch / set / blacklist logic lives in wallpaper.sh; this script only
shells out to it.

Usage: wallpaper-gui.py /path/to/wallpaper.sh
"""
import os
import subprocess
import sys
import threading

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk  # noqa: E402

N_CANDIDATES = 3
AUTO_DISMISS_SECONDS = 180
THUMB_SIZE = 300
EXIT_NO_CANDIDATES = 3

if len(sys.argv) < 2:
    print("usage: wallpaper-gui.py <path-to-wallpaper.sh>", file=sys.stderr)
    sys.exit(2)

SH_PATH = sys.argv[1]


def run_sh(args):
    return subprocess.run(["bash", SH_PATH] + args, capture_output=True, text=True)


def fetch_candidates(n):
    result = run_sh(["--candidates", str(n)])
    paths = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return [p for p in paths if os.path.isfile(p)]


def label_for(path):
    return os.path.splitext(os.path.basename(path))[0]


class WallpaperPicker(Gtk.Window):
    def __init__(self):
        super().__init__(title="Pick a wallpaper")
        self.set_keep_above(True)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(12)
        self.connect("delete-event", lambda _w, _e: self.finish(keep_current=True))
        self.connect("key-press-event", self.on_key_press)

        self.candidates = []
        self.selected_index = 0
        self.blacklist_checks = []
        self.radio_buttons = []
        self.image_widgets = []
        self.label_widgets = []
        self.remaining = AUTO_DISMISS_SECONDS
        self.exit_code = 0
        self._done = False

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(outer)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        title = Gtk.Label(label="<b>Pick a wallpaper</b>", use_markup=True)
        title.set_halign(Gtk.Align.START)
        self.countdown_label = Gtk.Label(label="")
        self.countdown_label.set_halign(Gtk.Align.END)
        header.pack_start(title, True, True, 0)
        header.pack_start(self.countdown_label, False, False, 0)
        outer.pack_start(header, False, False, 0)

        self.columns_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        outer.pack_start(self.columns_box, True, True, 0)

        radio_group = None
        for i in range(N_CANDIDATES):
            col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)

            event_box = Gtk.EventBox()
            image = Gtk.Image()
            image.set_size_request(THUMB_SIZE, THUMB_SIZE)
            event_box.add(image)
            event_box.connect("button-press-event", self.make_select_handler(i))
            col.pack_start(event_box, False, False, 0)
            self.image_widgets.append(image)

            name_label = Gtk.Label(label="loading...")
            name_label.set_line_wrap(True)
            col.pack_start(name_label, False, False, 0)
            self.label_widgets.append(name_label)

            if radio_group is None:
                radio = Gtk.RadioButton.new_with_label(None, "Use this")
                radio_group = radio
                radio.set_active(True)
            else:
                radio = Gtk.RadioButton.new_with_label_from_widget(radio_group, "Use this")
            radio.connect("toggled", self.make_radio_handler(i))
            col.pack_start(radio, False, False, 0)
            self.radio_buttons.append(radio)

            check = Gtk.CheckButton(label="Blacklist")
            check.connect("toggled", lambda _w: self.reset_countdown())
            col.pack_start(check, False, False, 0)
            self.blacklist_checks.append(check)

            self.columns_box.pack_start(col, True, True, 0)

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        shuffle_btn = Gtk.Button(label="Shuffle 3 new")
        shuffle_btn.connect("clicked", self.on_shuffle)
        keep_btn = Gtk.Button(label="Keep current")
        keep_btn.connect("clicked", lambda _b: self.finish(keep_current=True))
        set_btn = Gtk.Button(label="Set")
        set_btn.get_style_context().add_class("suggested-action")
        set_btn.connect("clicked", lambda _b: self.finish(keep_current=False))
        actions.pack_start(shuffle_btn, False, False, 0)
        actions.pack_end(set_btn, False, False, 0)
        actions.pack_end(keep_btn, False, False, 0)
        outer.pack_start(actions, False, False, 0)

        self.show_all()
        GLib.timeout_add(1000, self.tick)
        self.load_candidates_async()

    # --- selection / countdown -------------------------------------------------

    def make_select_handler(self, i):
        def handler(_widget, _event):
            if i < len(self.candidates):
                self.radio_buttons[i].set_active(True)
                self.reset_countdown()
        return handler

    def make_radio_handler(self, i):
        def handler(widget):
            if widget.get_active():
                self.selected_index = i
                self.reset_countdown()
        return handler

    def reset_countdown(self):
        self.remaining = AUTO_DISMISS_SECONDS

    def tick(self):
        if self._done:
            return False
        self.remaining -= 1
        mins, secs = divmod(max(self.remaining, 0), 60)
        self.countdown_label.set_text(f"auto-set in {mins}:{secs:02d}")
        if self.remaining <= 0:
            self.finish(keep_current=False)
            return False
        return True

    # --- candidate loading -------------------------------------------------------

    def load_candidates_async(self):
        for label in self.label_widgets:
            label.set_text("loading...")

        def worker():
            paths = fetch_candidates(N_CANDIDATES)
            GLib.idle_add(self.on_candidates_loaded, paths)

        threading.Thread(target=worker, daemon=True).start()

    def on_candidates_loaded(self, paths):
        if self._done:
            return False

        self.candidates = paths
        if not paths:
            # Nothing came back (offline / API down / all blacklisted).
            # Let wallpaper.sh's own fallback handle it.
            self.finish(keep_current=True, no_candidates=True)
            return False

        self.selected_index = 0
        for i in range(N_CANDIDATES):
            if i < len(paths):
                path = paths[i]
                self.set_thumbnail(i, path)
                self.label_widgets[i].set_text(label_for(path))
                self.radio_buttons[i].set_sensitive(True)
                self.blacklist_checks[i].set_sensitive(True)
                self.blacklist_checks[i].set_active(False)
            else:
                self.image_widgets[i].clear()
                self.label_widgets[i].set_text("(none)")
                self.radio_buttons[i].set_sensitive(False)
                self.blacklist_checks[i].set_sensitive(False)
        self.radio_buttons[0].set_active(True)
        return False

    def set_thumbnail(self, i, path):
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                path, THUMB_SIZE, THUMB_SIZE, True
            )
            self.image_widgets[i].set_from_pixbuf(pixbuf)
        except GLib.Error:
            self.label_widgets[i].set_text(f"{label_for(path)}\n(failed to load)")

    # --- actions -------------------------------------------------------------------

    def apply_blacklist_ticks(self):
        for i, check in enumerate(self.blacklist_checks):
            if check.get_active() and i < len(self.candidates):
                run_sh(["--blacklist", self.candidates[i]])

    def on_shuffle(self, _button):
        self.apply_blacklist_ticks()
        self.reset_countdown()
        self.load_candidates_async()

    def on_key_press(self, _widget, event):
        name = Gdk.keyval_name(event.keyval) or ""
        if name in ("1", "2", "3"):
            idx = int(name) - 1
            if idx < len(self.candidates):
                self.radio_buttons[idx].set_active(True)
        elif name == "Return":
            self.finish(keep_current=False)
        elif name in ("r", "R"):
            self.on_shuffle(None)
        elif name == "Escape":
            self.finish(keep_current=True)
        return False

    def finish(self, keep_current, no_candidates=False):
        if self._done:
            return
        self._done = True
        if no_candidates:
            self.exit_code = EXIT_NO_CANDIDATES
        else:
            self.apply_blacklist_ticks()
            if not keep_current and self.candidates:
                idx = self.selected_index if self.selected_index < len(self.candidates) else 0
                run_sh(["--set", self.candidates[idx]])
        Gtk.main_quit()


def main():
    win = WallpaperPicker()
    Gtk.main()
    win.destroy()
    sys.exit(win.exit_code)


if __name__ == "__main__":
    main()
