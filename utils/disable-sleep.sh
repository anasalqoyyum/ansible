#!/bin/sh

case "$1" in
1 | 0)
  sudo pmset -c disablesleep "$1"
  ;;
*)
  echo "Usage: $0 [0|1]"
  echo "  0: Enable sleep"
  echo "  1: Disable sleep"
  exit 1
  ;;
esac
