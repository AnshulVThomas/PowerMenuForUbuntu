#!/bin/bash

LOCKFILE="/tmp/power_menu.lock"

# Use flock to ensure only one instance runs
exec 200>"$LOCKFILE"
flock -n 200 || exit 1  # Exit if already locked

# Detect if running under Wayland or X11
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  IS_WAYLAND=true
else
  IS_WAYLAND=false
fi

# Run Zenity and capture stdout and exit code
TMP_OUTPUT=$(mktemp)
(
  zenity --info \
    --title="Power Menu" \
    --width=300 \
    --height=150 \
    --text="Choose a power option:\nClick Shutdown, Reboot or Log Out." \
    --ok-label="Shutdown" \
    --extra-button="Reboot" \
    --extra-button="Log Out" \
    --extra-button="Cancel"
  echo $? > "${TMP_OUTPUT}.status"
) >"$TMP_OUTPUT" &
ZENITY_PID=$!

if ! $IS_WAYLAND; then
  # Wait for Zenity to appear (only on X11)
  while true; do
    WIN_ID=$(xdotool search --name "Power Menu" | head -n 1)
    if [ -n "$WIN_ID" ]; then
      if xwininfo -id "$WIN_ID" | grep -q "IsViewable"; then
        break
      fi
    fi
    sleep 0.1
  done

  # Center the window (only on X11)
  SCREEN_WIDTH=$(xwininfo -root | awk '/Width/ {print $2}')
  SCREEN_HEIGHT=$(xwininfo -root | awk '/Height/ {print $2}')
  CENTER_X=$((SCREEN_WIDTH / 2 - 150))
  CENTER_Y=$((SCREEN_HEIGHT / 2 - 75))
  wmctrl -i -r "$WIN_ID" -e 0,$CENTER_X,$CENTER_Y,-1,-1
  wmctrl -i -a "$WIN_ID"
fi

# Wait for Zenity to close
wait $ZENITY_PID

# Read result
STATUS=$(cat "${TMP_OUTPUT}.status")
CHOICE=$(cat "$TMP_OUTPUT")
rm -f "$TMP_OUTPUT" "${TMP_OUTPUT}.status"

# If user closed the dialog
if [ "$STATUS" -ne 0 ] && [[ -z "$CHOICE" ]]; then
  exit 0
fi

# Execute based on user choice
case "$CHOICE" in
  "Reboot")
    systemctl reboot
    ;;
  "Log Out")
    gnome-session-quit --logout --no-prompt
    ;;
  "Cancel")
    exit 0
    ;;
  "")
    # OK clicked (Shutdown)
    systemctl poweroff
    ;;
esac
