#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -- bash "$0" "$@"
fi

stop=false
suppressed=false

lid_is_closed() {
  ioreg -r -k AppleClamshellState -d 4 2>/dev/null |
    grep -q '"AppleClamshellState" = Yes'
}

awdl_is_up() {
  ifconfig awdl0 2>/dev/null | grep -q '<[^>]*UP'
}

restore_awdl() {
  [ "$suppressed" = true ] || return

  echo "$(date '+%H:%M:%S') relinquishing AWDL control"
  ifconfig awdl0 up 2>/dev/null || true
  suppressed=false
}

cleanup() {
  trap - INT TERM EXIT

  # Don't manipulate networking while the lid is closed. In that state
  # macOS may be sleeping, entering sleep, or performing a DarkWake.
  if ! lid_is_closed; then
    restore_awdl
  fi
}

trap 'stop=true' INT TERM
trap cleanup EXIT

echo "Suppressing AWDL while lid is open. Ctrl-C to stop."

while [ "$stop" = false ]; do
  if lid_is_closed; then
    # Important: hand AWDL back to macOS before/while it transitions
    # through sleep and DarkWake.
    restore_awdl
  elif awdl_is_up; then
    echo "$(date '+%H:%M:%S') awdl0 came up → disabling"
    if ifconfig awdl0 down; then
      suppressed=true
    fi
  fi

  sleep 1 &
  wait $! 2>/dev/null || true
done
