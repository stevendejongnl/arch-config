#!/usr/bin/env bash
# Focus the agent sidebar of the current window; from the sidebar, go back to the previous pane.
# Opens the sidebar first if it is not open.
find_sidebar() { tmux list-panes -F '#{pane_id} #{@sidebar}' | awk '$2=="1"{print $1; exit}'; }
sb="$(find_sidebar)"
if [ -z "$sb" ]; then
  "$HOME/.config/tmux/scripts/sidebar-toggle.sh"
  sb="$(find_sidebar)"
  [ -n "$sb" ] && tmux select-pane -t "$sb"
  exit 0
fi
if [ "$(tmux display-message -p '#{pane_id}')" = "$sb" ]; then
  tmux select-pane -l
else
  tmux select-pane -t "$sb"
fi
