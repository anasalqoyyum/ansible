#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -- bash "$0" "$@"
fi

stop=false
cleaned_up=false

cleanup() {
  [ "$cleaned_up" = true ] && return
  cleaned_up=true
  trap - EXIT INT TERM

  echo
  echo "Re-enabling AWDL..."
  ifconfig awdl0 up 2>/dev/null || true
}

trap 'stop=true' INT TERM
trap cleanup EXIT

echo "Suppressing AWDL. Ctrl-C to stop."

while [ "$stop" = false ]; do
  if ifconfig awdl0 2>/dev/null | grep -q '<[^>]*UP'; then
    echo "$(date '+%H:%M:%S') awdl0 came up → disabling"
    ifconfig awdl0 down || true
  fi

  # Backgrounded so a SIGINT during the wait is delivered immediately.
  sleep 1 &
  wait $! 2>/dev/null || true
done
