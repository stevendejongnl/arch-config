"""Colours, CSS and small drawing widgets shared by the panels of the status bar popup."""
import math
import threading

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("PangoCairo", "1.0")
import cairo  # noqa: E402
from gi.repository import Gdk, GLib, Gtk, Pango, PangoCairo  # noqa: E402

from .colors import (BG, CARD, DIM, GREEN, LINE, MUTED, ORANGE, PURPLE, RED, TEAL, TEXT, TRACK, YELLOW)  # noqa: E402,F401

CSS = f"""
window {{ background: {BG}; }}
.tab {{ background: {CARD}; color: {DIM}; font-size: 10.5pt; font-weight: 700; padding: 7px 16px;
       border: 1px solid {LINE}; border-radius: 10px; box-shadow: none; background-image: none; }}
.tab:hover {{ background: {LINE}; }}
.tab:checked {{ background: {LINE}; color: {TEXT}; border-color: {TEAL}; }}
.tabhint {{ color: {MUTED}; font-size: 9pt; font-weight: 600; }}
.title {{ color: {TEXT}; font-size: 14pt; font-weight: 800; }}
.card {{ background: {CARD}; border: 1px solid {LINE}; border-radius: 14px; }}
.row, .row-now, .row-soon, .row-crit {{ padding: 10px 14px; }}
.row {{ background: {CARD}; border: 1px solid {LINE}; border-radius: 12px; }}
.row-now {{ background: {CARD}; border: 1px solid {GREEN}; border-radius: 12px; }}
.row-soon {{ background: {CARD}; border: 1px solid {TEAL}; border-radius: 12px; }}
.row-crit {{ background: {CARD}; border: 1px solid {RED}; border-radius: 12px; }}
.apptile {{ border-radius: 10px; font-size: 13pt; font-weight: 800; min-width: 40px; min-height: 40px; }}
.app {{ color: {DIM}; font-size: 8pt; font-weight: 800; letter-spacing: 1px; }}
.summary {{ color: {TEXT}; font-size: 10.5pt; font-weight: 700; }}
.body {{ color: {DIM}; font-size: 9.5pt; }}
.dismiss {{ background: transparent; color: {MUTED}; font-size: 10pt; padding: 2px 8px; border: none; border-radius: 999px;
           box-shadow: none; background-image: none; }}
.dismiss:hover {{ background: {LINE}; color: {TEXT}; }}
.pill {{ color: {BG}; font-size: 10pt; font-weight: 800; padding: 2px 10px; border-radius: 999px; }}
.name {{ color: {TEXT}; font-size: 13pt; font-weight: 700; }}
.plan {{ color: {DIM}; font-size: 9pt; font-weight: 700; padding: 1px 8px; border: 1px solid {LINE}; border-radius: 999px; }}
.muted {{ color: {MUTED}; font-size: 9pt; }}
.dim {{ color: {DIM}; font-size: 10pt; }}
.ringtitle {{ color: {DIM}; font-size: 8pt; font-weight: 800; letter-spacing: 1px; }}
.reset {{ color: {TEXT}; font-size: 10pt; font-weight: 600; }}
.section {{ color: {MUTED}; font-size: 8pt; font-weight: 800; letter-spacing: 1px; }}
.amount {{ color: {TEXT}; font-size: 9.5pt; font-weight: 600; }}
.big {{ color: {TEXT}; font-size: 28pt; font-weight: 800; }}
.elapsed {{ color: {TEXT}; font-size: 20pt; font-weight: 800; }}
.bigmuted {{ color: {MUTED}; font-size: 14pt; font-weight: 700; }}
.rowtitle {{ color: {TEXT}; font-size: 11pt; font-weight: 700; }}
.time {{ color: {DIM}; font-size: 10pt; font-weight: 700; }}
.action {{ background: {LINE}; color: {TEXT}; font-size: 9.5pt; font-weight: 700; padding: 4px 14px;
          border: none; border-radius: 999px; box-shadow: none; background-image: none; }}
.action:hover {{ background: #343A4D; }}
.action-primary {{ background: {TEAL}; color: {BG}; }}
.action-primary:hover {{ background: #6BF0EB; }}
.action-go {{ background: {GREEN}; color: {BG}; }}
.action-go:hover {{ background: #9BE6A8; }}
.action-warn {{ background: {YELLOW}; color: {BG}; }}
.action-warn:hover {{ background: #FFE29A; }}
.action-stop {{ background: {RED}; color: {BG}; }}
.action-stop:hover {{ background: #FF7D93; }}
scrolledwindow, viewport {{ background: transparent; }}
undershoot.top, undershoot.bottom, overshoot.top, overshoot.bottom {{ background: none; background-image: none; }}
scrollbar slider {{ background: {LINE}; border-radius: 4px; min-width: 5px; }}
"""

MARKUP = "<span foreground='{c}'>{t}</span>"


def install_css():
    css = Gtk.CssProvider()
    css.load_from_data(CSS.encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


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
    b.set_relief(Gtk.ReliefStyle.NONE)
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

    def __init__(self, height=8):
        super().__init__()
        self.set_size_request(-1, height)
        self.frac, self.color = 0.0, TEAL
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
                layout.set_markup(f"<span size='8000' foreground='{MUTED}'>{hour:02d}</span>", -1)
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
