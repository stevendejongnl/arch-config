#!/usr/bin/env bash

pane_path="$1"

toplevel=$(git -C "$pane_path" rev-parse --show-toplevel 2>/dev/null)

if [ -n "$toplevel" ]; then
  basename "$toplevel"
else
  basename "$pane_path"
fi
