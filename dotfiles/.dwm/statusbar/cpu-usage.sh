#!/bin/sh

get_cpu_usage() {
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.0f", 100 - $1}')

  # Color based on CPU load
  if [ "$cpu_usage" -ge 90 ]; then
    printf '\x0B'  # Critical - red
  elif [ "$cpu_usage" -ge 70 ]; then
    printf '\x0A'  # High - orange
  elif [ "$cpu_usage" -ge 50 ]; then
    printf '\x09'  # Medium - yellow
  else
    printf '\x08'  # Low - teal
  fi

  echo "[  $cpu_usage% ]$(printf '\x01')"
}

get_cpu_usage
