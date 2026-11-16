#!/bin/sh
# Print "1" while a sudo credential is cached (sudo would not ask for a password), else "0".
# Sudo timestamps are global (timestamp_type=global), so this holds for every terminal.

if sudo -n -v >/dev/null 2>&1; then
    printf '1'
else
    printf '0'
fi
