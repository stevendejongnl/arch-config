#!/bin/sh

get_memory_usage() {
  memory_info=$(free | grep Mem)

  total=$(echo "$memory_info" | awk '{print $2}')
  used=$(echo "$memory_info" | awk '{print $3}')
  percentage=$(echo "$memory_info" | awk '{printf "%.0f", ($3/$2) * 100}')

  total_h=$(free -h | grep Mem | awk '{print $2}')
  used_h=$(free -h | grep Mem | awk '{print $3}')
  swap_h=$(free -h | grep Swap | awk '{print $3}')

  # Color based on memory usage percentage
  if [ "$percentage" -ge 90 ]; then
    printf '\x0B'  # Critical
  elif [ "$percentage" -ge 80 ]; then
    printf '\x0A'  # High
  elif [ "$percentage" -ge 70 ]; then
    printf '\x09'  # Medium
  else
    printf '\x08'  # Low
  fi

  echo "[  $used_h/$total_h - $swap_h ]$(printf '\x01')"
}

get_memory_usage
