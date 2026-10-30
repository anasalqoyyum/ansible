#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 6 ]; then
  printf 'usage: log.sh <logfile> <phase> <decision> <why> <evidence> <result>\n' >&2
  exit 2
fi

logfile=$1
shift

logdir=$(dirname -- "$logfile")
if [ "$logdir" != "." ]; then
  mkdir -p -- "$logdir"
fi

if [ ! -s "$logfile" ]; then
  printf 'ts\tphase\tdecision\twhy\tevidence\tresult\n' >> "$logfile"
fi

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
clean() {
  local value
  value=$(printf '%s' "$1" | tr '\t\n\r' ' ')
  case "$value" in
    =*|+*|-*|@*) REPLY="'$value" ;;
    *) REPLY=$value ;;
  esac
}

clean "$1"; phase=$REPLY
clean "$2"; decision=$REPLY
clean "$3"; why=$REPLY
clean "$4"; evidence=$REPLY
clean "$5"; result=$REPLY
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$ts" "$phase" "$decision" "$why" "$evidence" "$result" >> "$logfile"
