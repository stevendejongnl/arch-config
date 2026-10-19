#!/usr/bin/env bash
# Claude Code hook -> tmux agent state.
# Usage (from hooks): agent-state.sh <working|idle|done|blocked|notification|seen|clear|reap>
# Sets pane option @agent_state, then rolls up to @wstate (window) and @sstate (session).
# Priority: blocked > done > working > idle. Always exits 0 so a hook never breaks Claude.

action="${1:-}"
input="$(cat 2>/dev/null || true)"

worst() {
  local best=""
  local rank=0 r s
  while read -r s; do
    case "$s" in
      blocked) r=4 ;;
      done) r=3 ;;
      working) r=2 ;;
      idle) r=1 ;;
      *) r=0 ;;
    esac
    if [ "$r" -gt "$rank" ]; then rank=$r; best=$s; fi
  done
  printf '%s' "$best"
}

if [ "$action" = "reap" ]; then
  # Clear state on panes that no longer run the agent (killed without SessionEnd), then re-roll up.
  tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{?#{@agent_state},1,0}' 2>/dev/null |
    while read -r id cmd has; do
      if [ "$has" = 1 ] && [ "$cmd" != claude ]; then
        tmux set-option -p -u -t "$id" @agent_state \; set-option -p -u -t "$id" @agent_kind \; set-option -p -u -t "$id" @agent_name 2>/dev/null
      fi
    done
  for w in $(tmux list-windows -a -F '#{window_id}' 2>/dev/null); do
    tmux set-option -w -t "$w" @wstate "$(tmux list-panes -t "$w" -F '#{@agent_state}' 2>/dev/null | worst)" 2>/dev/null
  done
  for sid in $(tmux list-sessions -F '#{session_id}' 2>/dev/null); do
    tmux set-option -t "$sid" @sstate "$(tmux list-panes -s -t "$sid" -F '#{@agent_state}' 2>/dev/null | worst)" 2>/dev/null
  done
  exit 0
fi

command -v tmux >/dev/null 2>&1 || exit 0

pane="${TMUX_PANE:-}"
[ "$action" = "seen" ] && pane="${2:-$pane}"
[ -n "$pane" ] || exit 0

case "$action" in
  notification)
    case "$input" in
      *permission_prompt*|*elicitation_dialog*) state=blocked ;;
      *idle_prompt*) state=idle ;;
      *) exit 0 ;;
    esac
    ;;
  done)
    # Finished turn in a pane the user is looking at counts as seen.
    active="$(tmux display-message -p -t "$pane" '#{&&:#{pane_active},#{&&:#{window_active},#{session_attached}}}' 2>/dev/null)"
    if [ "$active" = "1" ]; then state=idle; else state=done; fi
    ;;
  seen)
    # Run from tmux focus hooks with the target pane as $2.
    current="$(tmux display-message -p -t "$pane" '#{@agent_state}' 2>/dev/null)"
    [ "$current" = "done" ] || exit 0
    state=idle
    ;;
  working|idle|blocked) state="$action" ;;
  clear) state="" ;;
  *) exit 0 ;;
esac

if [ -n "$state" ]; then
  tmux set-option -p -t "$pane" @agent_state "$state" \; set-option -p -t "$pane" @agent_kind claude 2>/dev/null
else
  tmux set-option -p -u -t "$pane" @agent_state \; set-option -p -u -t "$pane" @agent_kind 2>/dev/null
fi

wstate="$(tmux list-panes -t "$pane" -F '#{@agent_state}' 2>/dev/null | worst)"
tmux set-option -w -t "$pane" @wstate "$wstate" 2>/dev/null

session="$(tmux display-message -p -t "$pane" '#{session_id}' 2>/dev/null)"
sstate="$(tmux list-panes -s -t "$session" -F '#{@agent_state}' 2>/dev/null | worst)"
tmux set-option -t "$session" @sstate "$sstate" 2>/dev/null

exit 0
