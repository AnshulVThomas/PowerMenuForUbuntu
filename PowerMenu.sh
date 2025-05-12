#!/bin/bash

LOCKFILE="/tmp/power_menu.lock"

# Use flock to ensure only one instance runs
exec 200>"$LOCKFILE"
flock -n 200 || exit 1  # Exit if already locked

CHOICE=$(yad --title="Power Menu" \
  --center \
  --buttons-layout=spread \
  --button="Shutdown:1" \
  --button="Reboot:2" \
  --button="Log Out:3" \
  --button="Cancel:0" \
  --text="Choose a power option:")

case $? in
  1)
    systemctl poweroff
    ;;
  2)
    systemctl reboot
    ;;
  3)
    gnome-session-quit --logout --no-prompt
    ;;
  0|*)
    exit 0
    ;;
esac

