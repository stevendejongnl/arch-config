"""Colours, CSS and small drawing widgets shared by the panels of the status bar popup."""
import math
import threading

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("PangoCairo", "1.0")
import cairo  # noqa: E402
from gi.repository import Gdk, GLib, Gtk, Pango, PangoCairo  # noqa: E402

from .colors import (BG, BORDER, CARD, DIM, GREEN, HOVER, LINE, MUTED, ORANGE, PURPLE, RED, TEAL, TEXT, TRACK, YELLOW)  # noqa: E402,F401

CSS = f"""
* {{ font-family: "Inter Tight", sans-serif; }}
window {{ background: {BG}; border: 1px solid {BORDER}; border-radius: 6px; }}
.head {{ padding: 14px 20px; border-bottom: 1px solid {LINE}; }}
.title {{ color: {TEXT}; font-size: 11pt; font-weight: 600; }}
.card {{ background: transparent; border: none; border-bottom: 1px solid {LINE}; border-radius: 0; }}
.row, .row-now, .row-soon, .row-crit {{ padding: 12px 20px; background: transparent; border: none;
                                        border-bottom: 1px solid {LINE}; border-radius: 0; }}
.row-tight {{ padding: 9px 20px; background: transparent; border: none; border-bottom: 1px solid {LINE}; border-radius: 0; }}
.row-now {{ border-left: 2px solid {GREEN}; }}
.row-crit {{ border-left: 2px solid {RED}; }}
.apptile {{ background: {LINE}; color: {TEXT}; border-radius: 6px; font-size: 11pt; font-weight: 600; min-width: 36px; min-height: 36px; }}
.app {{ color: {MUTED}; font-size: 9pt; font-weight: 500; letter-spacing: 1px; }}
.summary {{ color: {TEXT}; font-size: 10.5pt; font-weight: 600; }}
.body {{ color: {DIM}; font-size: 10pt; }}
.dismiss {{ background: transparent; color: {MUTED}; font-size: 10pt; padding: 2px 8px; border: none; border-radius: 6px;
           box-shadow: none; background-image: none; }}
.dismiss:hover {{ background: {HOVER}; color: {TEXT}; }}
.pill {{ color: {DIM}; font-size: 9pt; font-weight: 500; padding: 1px 8px; border: 1px solid {BORDER}; border-radius: 4px; }}
.name {{ color: {TEXT}; font-size: 11pt; font-weight: 600; }}
.plan {{ color: {DIM}; font-size: 9pt; font-weight: 500; padding: 1px 8px; border: 1px solid {BORDER}; border-radius: 4px; }}
.muted {{ color: {MUTED}; font-size: 9.5pt; }}
.dim {{ color: {DIM}; font-size: 10pt; }}
.ringtitle {{ color: {MUTED}; font-size: 9pt; font-weight: 500; letter-spacing: 1px; }}
.reset {{ color: {DIM}; font-size: 10pt; font-weight: 400; }}
.section {{ color: {MUTED}; font-size: 9pt; font-weight: 500; letter-spacing: 1px; }}
.amount {{ color: {TEXT}; font-size: 10pt; font-weight: 500; }}
.big {{ color: {TEXT}; font-size: 26pt; font-weight: 600; }}
.elapsed {{ color: {TEXT}; font-size: 20pt; font-weight: 600; }}
.bigmuted {{ color: {MUTED}; font-size: 14pt; font-weight: 500; }}
.rowtitle {{ color: {TEXT}; font-size: 11pt; font-weight: 600; }}
.time {{ color: {DIM}; font-size: 10pt; font-weight: 500; }}
.mono {{ font-family: "JetBrains Mono", monospace; color: {TEXT}; font-size: 9.5pt; }}
.monodim {{ font-family: "JetBrains Mono", monospace; color: {DIM}; font-size: 9.5pt; }}
.timer {{ font-family: "JetBrains Mono", monospace; color: {TEXT}; font-size: 12pt; font-weight: 500; }}
.rowname {{ color: {TEXT}; font-size: 10.5pt; font-weight: 500; }}
.rowdone {{ color: {DIM}; font-size: 10.5pt; }}
.action {{ background: transparent; color: {TEXT}; font-size: 10pt; font-weight: 500; padding: 6px 14px; min-height: 24px;
          border-width: 1px; border-style: solid; border-color: {BORDER}; border-radius: 6px; box-shadow: none; background-image: none; }}
button.action, button.flat.action {{ border-width: 1px; border-style: solid; border-color: {BORDER}; }}
.action:hover {{ background: {HOVER}; }}
button.action.action-primary {{ background: {TEXT}; border: 1px solid {TEXT}; }}
button.action.action-primary, button.action.action-primary label {{ color: {BG}; }}
.action-primary:hover {{ background: #FFFFFF; }}
button.action.action-go {{ border: 1px solid {GREEN}; }}
button.action.action-go, button.action.action-go label {{ color: {GREEN}; }}
.action-go:hover {{ background: {HOVER}; }}
button.action.action-warn {{ border: 1px solid {YELLOW}; }}
button.action.action-warn, button.action.action-warn label {{ color: {YELLOW}; }}
.action-warn:hover {{ background: {HOVER}; }}
button.action.action-stop {{ border: 1px solid {RED}; }}
button.action.action-stop, button.action.action-stop label {{ color: {RED}; }}
.action-stop:hover {{ background: {HOVER}; }}
scrolledwindow, viewport {{ background: transparent; }}
undershoot.top, undershoot.bottom, overshoot.top, overshoot.bottom {{ background: none; background-image: none; }}
scrollbar slider {{ background: {BORDER}; border-radius: 3px; min-width: 5px; }}
"""

MARKUP = "<span foreground='{c}'>{t}</span>"


def install_css():
    css = Gtk.CssProvider()
    css.load_from_data(CSS.encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_USER)


def rgb(hexcolor):
    h = hexcolor.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def label(text="", css=None, xalign=0.0, markup=False, wrap=False, ellipsize=False):
    lb = Gtk.Label(xalign=xalign)
    if markup:
        lb.set_markup(text)
    else:
        lb.set_text(text)
    if css:
        lb.get_style_context().add_class(css)
    if ellipsize:
        lb.set_ellipsize(Pango.EllipsizeMode.END)  # long text shortens instead of widening the window
    if wrap:
        lb.set_line_wrap(True)
        lb.set_max_width_chars(48)
    return lb


def button(text, css, on_click):
    b = Gtk.Button(label=text)
    b.get_style_context().add_class("action")
    if css:
        b.get_style_context().add_class(css)
    b.set_valign(Gtk.Align.CENTER)
    b.connect("clicked", lambda _b: on_click())
    return b


def margins(widget, top=0, bottom=0, start=0, end=0):
    widget.set_margin_top(top)
    widget.set_margin_bottom(bottom)
    widget.set_margin_start(start)
    widget.set_margin_end(end)
    return widget


def clear(container):
    for child in container.get_children():
        container.remove(child)


def run_async(work, done):
    """Run work() in a thread and call done(result) on the GTK main loop. A failure gives None."""
    def target():
        try:
            result = work()
        except Exception:  # noqa: BLE001 - a panel shows "no data" instead of crashing the popup
            result = None
        GLib.idle_add(lambda: done(result) and False)
    threading.Thread(target=target, daemon=True).start()


class Ring(Gtk.DrawingArea):
    """A percentage ring with an optional tick (where an even spread would be)."""

    def __init__(self, size=138):
        super().__init__()
        self.set_size_request(size, size)
        self.pct, self.pace, self.color = 0.0, None, TEAL
        self.connect("draw", self.on_draw)

    def set(self, pct, pace, color):
        self.pct, self.pace, self.color = pct, pace, color
        self.queue_draw()

    def on_draw(self, _w, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cx, cy, r, lw = w / 2, h / 2, min(w, h) / 2 - 13, 12
        start = -math.pi / 2
        cr.set_line_cap(cairo.LINE_CAP_ROUND)
        cr.set_line_width(lw)
        cr.set_source_rgb(*rgb(TRACK))
        cr.arc(cx, cy, r, 0, 2 * math.pi)
        cr.stroke()
        if self.pct >= 0.5:
            end = start + 2 * math.pi * min(self.pct, 100) / 100
            cr.set_line_width(lw + 9)
            cr.set_source_rgba(*rgb(self.color), 0.16)
            cr.arc(cx, cy, r, start, end)
            cr.stroke()
            cr.set_line_width(lw)
            cr.set_source_rgb(*rgb(self.color))
            cr.arc(cx, cy, r, start, end)
            cr.stroke()
        if self.pace is not None:
            a = start + 2 * math.pi * self.pace
            cr.set_line_cap(cairo.LINE_CAP_BUTT)
            cr.set_line_width(2.5)
            cr.set_source_rgba(*rgb(TEXT), 0.9)
            cr.move_to(cx + (r - lw / 2 - 4) * math.cos(a), cy + (r - lw / 2 - 4) * math.sin(a))
            cr.line_to(cx + (r + lw / 2 + 4) * math.cos(a), cy + (r + lw / 2 + 4) * math.sin(a))
            cr.stroke()
        layout = PangoCairo.create_layout(cr)
        layout.set_markup(
            f"<span font_family='sans-serif' size='27000' weight='heavy' foreground='{TEXT}'>{round(self.pct)}</span>"
            f"<span font_family='sans-serif' size='12000' weight='bold' foreground='{MUTED}'>%</span>", -1)
        lw_px, lh_px = layout.get_pixel_size()
        cr.move_to(cx - lw_px / 2, cy - lh_px / 2)
        PangoCairo.show_layout(cr, layout)


def pill_path(cr, x, y, w, h):
    r = min(h / 2, w / 2)
    cr.new_sub_path()
    cr.arc(x + r, y + r, r, math.pi / 2, 3 * math.pi / 2)
    cr.arc(x + w - r, y + r, r, -math.pi / 2, math.pi / 2)
    cr.close_path()


class Bar(Gtk.DrawingArea):
    """A thin rounded progress bar."""

    def __init__(self, height=6):
        super().__init__()
        self.set_size_request(-1, height)
        self.frac, self.color = 0.0, GREEN
        self.connect("draw", self.on_draw)

    def set(self, frac, color):
        self.frac, self.color = frac, color
        self.queue_draw()

    def on_draw(self, _w, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cr.set_source_rgb(*rgb(TRACK))
        pill_path(cr, 0, 0, w, h)
        cr.fill()
        if self.frac > 0:
            cr.set_source_rgb(*rgb(self.color))
            pill_path(cr, 0, 0, max(w * min(self.frac, 1), h), h)
            cr.fill()


class Segments(Gtk.DrawingArea):
    """A thin bar of coloured parts, each a share of the whole (a day goal), on a track."""

    def __init__(self, height=6):
        super().__init__()
        self.set_size_request(-1, height)
        self.parts = []
        self.connect("draw", self.on_draw)

    def set(self, parts):
        """parts: list of (fraction of the full bar, colour)."""
        self.parts = parts
        self.queue_draw()

    def on_draw(self, _w, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cr.set_source_rgb(*rgb(TRACK))
        pill_path(cr, 0, 0, w, h)
        cr.fill()
        cr.save()
        pill_path(cr, 0, 0, w, h)
        cr.clip()
        x = 0.0
        for frac, color in self.parts:
            width = w * min(max(frac, 0), 1)
            cr.set_source_rgb(*rgb(color))
            cr.rectangle(x, 0, width, h)
            cr.fill()
            x += width
        cr.restore()


class Timeline(Gtk.DrawingArea):
    """A day as a horizontal strip: blocks of (start minute, end minute, colour), and a now marker."""

    def __init__(self, height=64):
        super().__init__()
        self.set_size_request(-1, height)
        self.blocks, self.lo, self.hi, self.now = [], 8 * 60, 18 * 60, None
        self.connect("draw", self.on_draw)

    def set(self, blocks, now=None, lo_hour=8, hi_hour=18):
        """blocks: list of (start, end, colour) in minutes since midnight."""
        if blocks:
            lo_hour = min(lo_hour, min(b[0] for b in blocks) // 60)
            hi_hour = max(hi_hour, -(-max(b[1] for b in blocks) // 60))
        self.blocks, self.now = sorted(blocks), now
        self.lo, self.hi = lo_hour * 60, max(hi_hour, lo_hour + 1) * 60
        self.queue_draw()

    def lanes(self):
        """Give overlapping blocks their own row."""
        ends, placed = [], []
        for start, end, color in self.blocks:
            for i, e in enumerate(ends):
                if e <= start:
                    ends[i] = end
                    placed.append((start, end, color, i))
                    break
            else:
                ends.append(end)
                placed.append((start, end, color, len(ends) - 1))
        return placed, max(len(ends), 1)

    def on_draw(self, _w, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        axis = 16
        area_h = h - axis
        span = self.hi - self.lo

        def x_of(minute):
            return (minute - self.lo) / span * w

        cr.set_source_rgb(*rgb(TRACK))
        pill_path(cr, 0, 0, w, area_h)
        cr.fill()
        # hour grid and labels
        layout = PangoCairo.create_layout(cr)
        for hour in range(self.lo // 60, self.hi // 60 + 1):
            x = x_of(hour * 60)
            if hour * 60 not in (self.lo, self.hi):
                cr.set_source_rgba(*rgb(LINE), 0.9)
                cr.set_line_width(1)
                cr.move_to(round(x) + 0.5, 3)
                cr.line_to(round(x) + 0.5, area_h - 3)
                cr.stroke()
            if (hour - self.lo // 60) % 2 == 0 or self.hi - self.lo <= 6 * 60:
                layout.set_markup(f"<span font_family='Inter Tight' size='8000' foreground='{MUTED}'>{hour:02d}</span>", -1)
                tw, _th = layout.get_pixel_size()
                cr.move_to(min(max(x - tw / 2, 0), w - tw), area_h + 1)
                PangoCairo.show_layout(cr, layout)
        # blocks
        placed, lane_count = self.lanes()
        pad = 4
        lane_h = (area_h - 2 * pad - (lane_count - 1) * 3) / lane_count
        for start, end, color, lane in placed:
            x0, x1 = x_of(start), x_of(end)
            y = pad + lane * (lane_h + 3)
            past = self.now is not None and end <= self.now
            cr.set_source_rgba(*rgb(color), 0.45 if past else 0.95)
            pill_path(cr, x0 + 1, y, max(x1 - x0 - 2, 4), lane_h)
            cr.fill()
        # now marker
        if self.now is not None and self.lo <= self.now <= self.hi:
            x = x_of(self.now)
            cr.set_source_rgb(*rgb(RED))
            cr.set_line_width(2)
            cr.move_to(x, 1)
            cr.line_to(x, area_h - 1)
            cr.stroke()
            cr.arc(x, 3, 3, 0, 2 * math.pi)
            cr.fill()
