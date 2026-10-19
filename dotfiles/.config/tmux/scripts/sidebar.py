#!/usr/bin/env python3
"""Herdr-style sidebar for tmux: panes of this window on top, agents elsewhere below.

PANES = every pane in the sidebar's own window (the claude pane, the hunk pane, ...).
OTHER AGENTS = agent panes in all other windows, most urgent first.
ZOMBIES = claude processes with no live pane (or stopped/defunct). Listed, not jumpable.
The sidebar re-executes itself when this file changes (skipped if the new file does not compile).
Keys: j/k or arrows move the cursor, Enter jumps, Enter on a zombie opens it (new window, resumes session), x kills it (asks y/n),
q closes. Mouse click jumps.
The active pane is marked with '>' and bold.
State marks (ASCII): ! blocked, + done, ~ working, . idle, ? agent running but state unknown.
"""
import curses
import json
import os
import signal
import subprocess
import sys
import time

SEP = "\x1f"
FMT = SEP.join([
    "#{window_id}", "#{window_name}", "#{pane_id}", "#{pane_index}",
    "#{@agent_state}", "#{@agent_name}", "#{@sidebar}", "#{pane_active}",
    "#{pane_current_command}", "#{pane_current_path}", "#{session_name}", "#{@agent_kind}",
])
MARK = {"blocked": "!", "done": "+", "working": "~", "idle": ".", "unknown": "?"}
RANK = {"blocked": 4, "done": 3, "working": 2, "idle": 1, "unknown": 1, "": 0}
AGENT_COMMANDS = ("claude",)
REFRESH = 0.5
REAP_EVERY = 5.0
ZOMBIE_EVERY = 2.0
TMUX_AGENT = os.path.expanduser("~/.config/tmux/scripts/tmux-agent")
REAP = os.path.expanduser("~/.config/tmux/scripts/agent-state.sh")


def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True).stdout


def own_window():
    pane = os.environ.get("TMUX_PANE", "")
    return tmux("display-message", "-p", "-t", pane, "#{window_id}").strip()


def snapshot(window_id):
    panes = []
    others = []
    for line in tmux("list-panes", "-a", "-F", FMT).splitlines():
        (wid, wname, pid, pidx, state, name, sidebar, pactive,
         command, cwd, sess, kind) = line.split(SEP)
        if sidebar == "1":
            continue
        if state and command not in AGENT_COMMANDS:
            state, name, kind = "", "", ""  # stale: agent process is gone
        if not state and command in AGENT_COMMANDS:
            # Agent running but no hook has fired yet (started before hooks, or no hooks).
            state, kind = "unknown", command
        cwd_base = cwd.rstrip("/").split("/")[-1]
        if wid == window_id:
            label = name or (kind if state else command) or "pane"
            extra = f" {cwd_base}" if cwd_base and cwd_base != label else ""
            panes.append({"pane_id": pid, "index": int(pidx), "state": state,
                          "text": f"{label}{extra}", "active": pactive == "1"})
        elif state:
            others.append({"pane_id": pid, "state": state, "sess": sess,
                           "text": f"{name or wname or cwd_base} ({wname})" if name else (wname or cwd_base)})
    panes.sort(key=lambda p: p["index"])
    others.sort(key=lambda a: (-RANK[a["state"]], a["text"]))
    return panes, others


def zombies():
    res = subprocess.run([TMUX_AGENT, "agent", "zombies"], stdin=subprocess.DEVNULL, capture_output=True, text=True)
    try:
        return json.loads(res.stdout)["result"]
    except (ValueError, KeyError):
        return []


SELF = os.path.abspath(__file__)


def self_mtime():
    try:
        return os.stat(SELF).st_mtime_ns
    except OSError:
        return 0


def reload_error():
    """Return None if the file on disk compiles, else a short error text."""
    try:
        with open(SELF, encoding="utf-8") as fh:
            compile(fh.read(), SELF, "exec")
    except (SyntaxError, ValueError, OSError) as err:
        return f"reload skipped: {type(err).__name__} {getattr(err, 'lineno', '') or ''}".strip()
    return None


def kill_zombie(z):
    """SIGTERM a zombie after re-checking it is still listed (guards against pid reuse)."""
    if z["reason"] == "defunct":
        return "defunct: parent must reap it"
    if not any(c["pid"] == z["pid"] for c in zombies()):
        return "gone or no longer a zombie"
    try:
        os.kill(z["pid"], signal.SIGTERM)
        if z["reason"] == "stopped":
            os.kill(z["pid"], signal.SIGCONT)  # a stopped process only handles TERM once resumed
    except OSError as err:
        return f"kill failed: {err.strerror}"
    return f"sent TERM to {z['pid']}"


def revive(z):
    res = subprocess.run([TMUX_AGENT, "agent", "revive", str(z["pid"])],
                         stdin=subprocess.DEVNULL, capture_output=True, text=True)
    if res.returncode == 0:
        return f"opened {z['pid']} in new window"
    try:
        return json.loads(res.stderr)["error"]["message"]
    except (ValueError, KeyError):
        return "revive failed"


def jump(pane_id):
    tmux("switch-client", "-t", pane_id)
    tmux("select-window", "-t", pane_id)
    tmux("select-pane", "-t", pane_id)


def run(stdscr):
    curses.curs_set(0)
    curses.use_default_colors()
    curses.mousemask(curses.ALL_MOUSE_EVENTS)
    stdscr.timeout(200)
    curses.init_pair(1, curses.COLOR_RED, -1)
    curses.init_pair(2, curses.COLOR_GREEN, -1)
    curses.init_pair(3, curses.COLOR_YELLOW, -1)
    curses.init_pair(4, curses.COLOR_CYAN, -1)
    colors = {"blocked": 1, "done": 2, "working": 3, "idle": 4, "unknown": 0, "": 0}

    window_id = own_window()
    last_reap = 0.0
    last_zombie = -ZOMBIE_EVERY
    zombie_rows = []
    loaded_mtime = self_mtime()
    bad_mtime = 0  # mtime of a file version that failed to compile
    confirm = None  # zombie dict awaiting y/n
    notice = ("", 0.0)  # (text, expiry)
    sel = None  # keyboard cursor; None until a key moves it
    last = 0.0
    panes, others = [], []
    while True:
        now = time.monotonic()
        if now - last_reap >= REAP_EVERY:
            subprocess.run([REAP, "reap"], stdin=subprocess.DEVNULL, capture_output=True)
            last_reap = now
        if now - last_zombie >= ZOMBIE_EVERY:
            zombie_rows = zombies()
            last_zombie = now
        if now - last >= REFRESH:
            current = self_mtime()
            if current != loaded_mtime and current != bad_mtime and not confirm:
                err = reload_error()
                if err is None:
                    curses.endwin()
                    os.execv(sys.executable, [sys.executable, SELF])
                bad_mtime = current
                notice = (err, time.monotonic() + 8)
            window_id = own_window() or window_id
            panes, others = snapshot(window_id)
            last = now

        rows = []  # (text, state, pane_id, active)
        for p in panes:
            mark = MARK.get(p["state"], " ")
            rows.append((f"{mark} {p['text']}", p["state"], p["pane_id"], p["active"]))
        pane_count = len(rows)
        for a in others:
            rows.append((f"{MARK[a['state']]} {a['text']}", a["state"], a["pane_id"], False))
        other_end = len(rows)
        for z in zombie_rows:
            base = z["cwd"].rstrip("/").split("/")[-1] or "?"
            rows.append((f"Z {base} {z['pid']} {z['reason']} {z['age']}", "blocked", z.get("pane_id") or None, False))
        if sel is not None:
            sel = max(0, min(sel, len(rows) - 1)) if rows else None

        stdscr.erase()
        h, w = stdscr.getmaxyx()
        y = 0
        pos = {}
        stdscr.addnstr(y, 0, "PANES", w - 1, curses.A_BOLD)
        y += 1
        for i, (text, state, pid, active) in enumerate(rows):
            if i == pane_count and others:
                y += 1
                if y < h:
                    stdscr.addnstr(y, 0, "OTHER AGENTS", w - 1, curses.A_BOLD)
                y += 1
            if i == other_end and zombie_rows:
                y += 1
                if y < h:
                    stdscr.addnstr(y, 0, "ZOMBIES", w - 1, curses.A_BOLD)
                y += 1
            if y >= h:
                break
            attr = curses.color_pair(colors[state])
            line = ("> " if active else "  ") + text
            if active:
                attr |= curses.A_BOLD
            if i == sel:
                attr |= curses.A_REVERSE
            stdscr.addnstr(y, 0, line.ljust(w - 1), w - 1, attr)
            pos[y] = i
            y += 1
        if not zombie_rows and y + 2 < h:
            stdscr.addnstr(y + 1, 0, "ZOMBIES", w - 1, curses.A_BOLD)
            stdscr.addnstr(y + 2, 0, "  none", w - 1, curses.A_DIM)
        footer = ""
        if confirm:
            footer = f"kill {confirm['pid']}? y/n"
        elif notice[0] and now < notice[1]:
            footer = notice[0]
        if footer and h > 1:
            stdscr.addnstr(h - 1, 0, footer.ljust(w - 1), w - 1, curses.A_BOLD | curses.color_pair(3))
        stdscr.refresh()

        ch = stdscr.getch()
        if confirm:
            if ch == -1:
                continue
            if ch == ord("y"):
                notice = (kill_zombie(confirm), time.monotonic() + 4)
                last_zombie = -ZOMBIE_EVERY
            confirm = None
            continue
        if ch in (ord("q"), 27):
            return
        if ch == ord("x") and sel is not None and sel >= other_end:
            confirm = zombie_rows[sel - other_end]
        if ch in (ord("j"), curses.KEY_DOWN):
            sel = 0 if sel is None else sel + 1
        elif ch in (ord("k"), curses.KEY_UP):
            sel = 0 if sel is None else sel - 1
        elif ch in (10, curses.KEY_ENTER) and sel is not None and sel >= other_end and not rows[sel][2]:
            notice = (revive(zombie_rows[sel - other_end]), time.monotonic() + 5)
            last_zombie = -ZOMBIE_EVERY
        elif ch in (10, curses.KEY_ENTER) and rows and sel is not None and rows[sel][2]:
            jump(rows[sel][2])
            sel = None
            last = 0.0
        elif ch == curses.KEY_MOUSE:
            try:
                _, _, my, _, bstate = curses.getmouse()
            except curses.error:
                continue
            if bstate & curses.BUTTON1_CLICKED and my in pos and rows[pos[my]][2]:
                jump(rows[pos[my]][2])
                sel = None
                last = 0.0
        elif ch == curses.KEY_RESIZE:
            last = 0.0


if __name__ == "__main__":
    curses.wrapper(run)
