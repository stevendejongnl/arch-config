#!/usr/bin/env bash
# Toggle the agent sidebar in the current window (full-height left pane, 30 cols).
existing="$(tmux list-panes -F '#{pane_id} #{@sidebar}' | awk '$2=="1"{print $1; exit}')"
if [ -n "$existing" ]; then
  tmux kill-pane -t "$existing"
  exit 0
fi
new="$(tmux split-window -hbf -l 30 -d -P -F '#{pane_id}' "$HOME/.config/tmux/scripts/sidebar.py")"
tmux set-option -p -t "$new" @sidebar 1
