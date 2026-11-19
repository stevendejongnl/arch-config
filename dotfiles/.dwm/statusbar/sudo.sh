#!/bin/sh

# Sudo chip: an open padlock in a red chip while sudo is unlocked, nothing while it is locked.
# A click runs "sudo -k" (see click.sh). `sudo -n -v` only checks the ticket and logs nothing; the
# ticket is global and does not expire (timestamp_type=global, timestamp_timeout=-1 in sudoers),
# so the check does not extend anything and the 1s status bar loop can run it.

UNLOCKED=$(printf '\xef\x82\x9c')   # Nerd Font unlock (U+F09C)
CLICK=$(printf '\x17')              # statuscmd byte: click locks sudo again (see click.sh)
BADGE=$(printf '\x05')              # red chip
RESET=$(printf '\x01')

sudo -n -v 2>/dev/null || exit 0
printf '%s%s %s %s ' "$CLICK" "$BADGE" "$UNLOCKED" "$RESET"
