#!/bin/sh
# Keeps the X idle settings right when pep (the keep-awake tray tool) toggles them.
#
# Switching pep off restores the settings it saved: it re-enables DPMS (monitors off after
# 10 minutes) and puts back whatever screensaver timeout was set when pep was switched on.
# What we want while pep is off: DPMS never on, the lock (xss-lock -> slock) after 30 minutes.
# While pep is on, pep owns the settings and nothing is touched.
#
# Only a setting that drifted is changed: setting the screensaver timeout restarts the idle
# timer, so doing it every round would keep postponing the lock.

LOCK_SECONDS=1800
INTERVAL=5

pep_is_on() {
  pgrep -f -- '--who=pep' > /dev/null
}

while sleep "$INTERVAL"; do
  state=$(xset q 2> /dev/null) || continue

  case "$state" in
    *"DPMS is Enabled"*) xset -dpms ;;
  esac

  pep_is_on && continue

  if ! printf '%s\n' "$state" | grep -Eq "timeout: +$LOCK_SECONDS +cycle: +0"; then
    xset s "$LOCK_SECONDS" 0
    xset s blank
  fi
done
