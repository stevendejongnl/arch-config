"""Claude tab: one block per account with flat 5 hour and 7 day rows, reset times and extra-usage credits."""
from gi.repository import Gtk

from . import claude_data as cd
from .theme import (DIM, GREEN, MARKUP, MUTED, ORANGE, RED, TEXT, Bar, label)

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


class WindowRow(Gtk.Grid):
    """One window of an account: a small caps title, a bar, and the percentage with the reset time."""

    def __init__(self, title):
        super().__init__(column_spacing=14)
        self.get_style_context().add_class("row")
        self.bar = Bar(6)
        self.bar.set_hexpand(True)
        self.bar.set_valign(Gtk.Align.CENTER)
        self.value = label("", "amount", 1.0, markup=True)
        self.value.set_size_request(190, -1)
        head = label(title, "ringtitle")
        head.set_size_request(70, -1)
        self.attach(head, 0, 0, 1, 1)
        self.attach(self.bar, 1, 0, 1, 1)
        self.attach(self.value, 2, 0, 1, 1)

    def update(self, w, fmt_when):
        self.bar.set(w["pct"] / 100, cd.level_color(w["pct"]))
        pct = f"<span foreground='{TEXT}' weight='600'>{round(w['pct'])}%</span>"
        if w["passed"]:
            tail = f" <span foreground='{MUTED}'>· window reset</span>"
        elif w["left"] is not None:
            tail = f" <span foreground='{DIM}'>· resets in {cd.fmt_span(w['left'])}</span>"
        else:
            tail = ""
        self.value.set_markup(pct + tail)


class Card(Gtk.Box):
    """One account: the header row, the 5 hour and 7 day rows, and the extra-usage row."""

    def __init__(self, profile, short, name, accent):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.profile = profile
        self.get_style_context().add_class("card")

        self.plan = label("", "plan", 0.5)
        self.status = label("", "muted", 1.0, markup=True)
        head = Gtk.Box(spacing=10)
        head.get_style_context().add_class("row")
        head.pack_start(label(name, "name"), False, False, 0)
        head.pack_start(self.plan, False, False, 0)
        head.pack_end(self.status, False, False, 0)

        self.session = WindowRow("5 HOURS")
        self.week = WindowRow("7 DAYS")

        self.credit_amount = label("", "amount", 1.0, markup=True)
        self.credit_bar = Bar(6)
        self.credit_bar.set_valign(Gtk.Align.CENTER)
        self.credit_note = label("", "muted", 1.0, markup=True)
        credit = Gtk.Grid(column_spacing=14)
        credit.get_style_context().add_class("row")
        credit_title = label("EXTRA", "ringtitle")
        credit_title.set_size_request(70, -1)
        self.credit_bar.set_hexpand(True)
        self.credit_amount.set_size_request(190, -1)
        credit.attach(credit_title, 0, 0, 1, 1)
        credit.attach(self.credit_bar, 1, 0, 1, 1)
        credit.attach(self.credit_amount, 2, 0, 1, 1)

        for child in (head, self.session, self.week, credit):
            self.pack_start(child, False, False, 0)

    def update(self, data):
        w = cd.summarize(data)
        self.session.update(w["session"], "%H:%M")
        self.week.update(w["week"], "%a %H:%M")
        self.plan.set_text((data.get("subscription") or "").title())
        live, color, text = cd.health(data)
        if live:
            text, color = pace_text(w["session"])
            text, color = (text or "Live"), (color if text else GREEN)
        self.status.set_markup(MARKUP.format(c=color, t=text))

        limit = float(data.get("credits_limit") or 0)
        used = float(data.get("credits_used") or 0)
        symbol = "€" if data.get("credits_currency") == "EUR" else ""
        blocked = bool(data.get("credits_blocked"))
        reason = (data.get("credits_disabled_reason") or "").replace("_", " ").removesuffix(" until")
        if limit > 0:
            frac = used / limit
            tail = f" <span foreground='{RED}'>· blocked{(' · ' + reason) if reason else ''}</span>" if blocked else ""
            self.credit_amount.set_markup(
                f"<span foreground='{TEXT}' weight='600'>{symbol}{used:.2f}</span>"
                f" <span foreground='{MUTED}'>/ {symbol}{limit:g}</span>{tail}")
            self.credit_bar.set(frac, RED if blocked or frac >= 1 else cd.level_color(frac * 100))
        else:
            self.credit_amount.set_markup(MARKUP.format(c=MUTED, t="off · no extra usage budget"))
            self.credit_bar.set(0, GREEN)


class ClaudePanel(Gtk.Box):
    name = "claude"
    title = "Claude"

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0, valign=Gtk.Align.START)
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
