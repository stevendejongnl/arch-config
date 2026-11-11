"""Claude tab: one card per account with 5 hour and weekly rings, reset times and extra-usage credits."""
from gi.repository import Gtk

from . import claude_data as cd
from .theme import (DIM, GREEN, MARKUP, MUTED, ORANGE, RED, TEAL, Bar, Ring, label, margins)

ACCENTS = {p: accent for p, _short, _name, accent in cd.PROFILES}


def pace_text(w):
    """A short line and colour on how the usage compares with an even spread over the window."""
    if w["passed"] or w["pace"] is None:
        return "", MUTED
    delta = w["pct"] - w["pace"] * 100
    if delta > 15:
        return f"{round(delta)} pts ahead of pace", RED
    if delta > 5:
        return f"{round(delta)} pts ahead of pace", ORANGE
    if delta < -5:
        return f"{round(-delta)} pts under pace", GREEN
    return "On pace", GREEN


class RingColumn(Gtk.Box):
    def __init__(self, title):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self.ring = Ring()
        self.reset = label("", "reset", 0.5, markup=True)
        self.when = label("", "muted", 0.5)
        self.pace = label("", "muted", 0.5, markup=True)
        self.pack_start(self.ring, False, False, 0)
        self.pack_start(label(title, "ringtitle", 0.5), False, False, 4)
        self.pack_start(self.reset, False, False, 0)
        self.pack_start(self.when, False, False, 0)
        self.pack_start(self.pace, False, False, 2)

    def update(self, w, fmt_when):
        self.ring.set(w["pct"], w["pace"], cd.level_color(w["pct"]))
        if w["passed"]:
            self.reset.set_markup(MARKUP.format(c=MUTED, t="Window reset"))
            self.when.set_text("")
        elif w["left"] is not None:
            self.reset.set_text(f"Resets in {cd.fmt_span(w['left'])}")
            self.when.set_text(w["reset"].strftime(fmt_when))
        else:
            self.reset.set_text("")
            self.when.set_text("")
        text, color = pace_text(w)
        self.pace.set_markup(MARKUP.format(c=color, t=text))


class Card(Gtk.Box):
    def __init__(self, profile, short, name, accent):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.profile = profile
        self.get_style_context().add_class("card")
        self.set_size_request(318, -1)

        pill = label(short, "pill", 0.5)
        provider = Gtk.CssProvider()
        provider.load_from_data(f".pill-{profile} {{ background: {accent}; }}".encode())
        pill.get_style_context().add_class(f"pill-{profile}")
        pill.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        self.plan = label("", "plan", 0.5)

        head = Gtk.Box(spacing=10)
        head.pack_start(pill, False, False, 0)
        head.pack_start(label(name, "name"), False, False, 0)
        head.pack_end(self.plan, False, False, 0)

        self.health = label("", "muted", markup=True)
        self.session = RingColumn("5 HOURS")
        self.week = RingColumn("WEEK")
        rings = Gtk.Box(homogeneous=True, spacing=6)
        rings.pack_start(self.session, True, True, 0)
        rings.pack_start(self.week, True, True, 0)

        self.credit_amount = label("", "amount", 1.0, markup=True)
        credit_row = Gtk.Box()
        credit_row.pack_start(label("EXTRA USAGE", "section"), True, True, 0)
        credit_row.pack_end(self.credit_amount, False, False, 0)
        self.credit_bar = Bar()
        self.credit_note = label("", "muted", markup=True)

        for child, before, after in (
            (head, 18, 0), (self.health, 4, 0), (rings, 16, 0),
            (credit_row, 18, 0), (self.credit_bar, 7, 0), (self.credit_note, 6, 18),
        ):
            margins(child, before, after, 20, 20)
            self.pack_start(child, False, False, 0)

    def update(self, data):
        w = cd.summarize(data)
        self.session.update(w["session"], "%H:%M")
        self.week.update(w["week"], "%a %H:%M")
        self.plan.set_text((data.get("subscription") or "").upper())
        _live, color, text = cd.health(data)
        self.health.set_markup(MARKUP.format(c=color, t=f"●  {text}"))

        limit = float(data.get("credits_limit") or 0)
        used = float(data.get("credits_used") or 0)
        symbol = "€" if data.get("credits_currency") == "EUR" else ""
        blocked = bool(data.get("credits_blocked"))
        reason = (data.get("credits_disabled_reason") or "").replace("_", " ").removesuffix(" until")
        if limit > 0:
            frac = used / limit
            self.credit_amount.set_markup(f"{symbol}{used:.2f} <span foreground='{MUTED}'>/ {symbol}{limit:g}</span>")
            self.credit_bar.set(frac, RED if blocked or frac >= 1 else cd.level_color(frac * 100))
        else:
            self.credit_amount.set_markup(MARKUP.format(c=MUTED, t="off"))
            self.credit_bar.set(0, TEAL)
        if limit <= 0:
            self.credit_note.set_markup(MARKUP.format(c=MUTED, t="No extra usage budget"))
        elif blocked:
            self.credit_note.set_markup(MARKUP.format(c=RED, t="Blocked" + (f"  ·  {reason}" if reason else "")))
        else:
            self.credit_note.set_markup(MARKUP.format(c=GREEN, t="Available"))


class ClaudePanel(Gtk.Box):
    name = "claude"
    title = "Claude"

    def __init__(self):
        super().__init__(spacing=14, valign=Gtk.Align.START)
        self.cards = [Card(p, s, n, a) for p, s, n, a in cd.PROFILES if cd.load(p)]
        for card in self.cards:
            self.pack_start(card, False, False, 0)
        if not self.cards:
            self.pack_start(label("No usage data found in ~/.claude/accounts", "muted"), False, False, 0)

    @staticmethod
    def available():
        return any(cd.load(p) for p, *_ in cd.PROFILES)

    def tick(self, _seconds):
        for card in self.cards:
            data = cd.load(card.profile)
            if data:
                card.update(data)

    def load(self):
        return None

    def hint(self):
        parts = []
        for profile, short, _n, _a in cd.PROFILES:
            data = cd.load(profile)
            if data:
                w = cd.summarize(data)
                parts.append(f"{short} {round(max(w['session']['pct'], w['week']['pct']))}%")
        return "  ".join(parts)
