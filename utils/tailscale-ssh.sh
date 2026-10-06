#!/usr/bin/env bash
set -euo pipefail

for dependency in tailscale jq; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$dependency" >&2
    exit 1
  fi
done

status=$(tailscale status --json)

jq -r '
  def ssh_commands(ipv6):
    [.TailscaleIPs[]? | select(contains(":") == ipv6) | "`ssh \(.)`"]
    | if length == 0 then "Unavailable" else join("<br>") end;

  if .BackendState != "Running" then
    error("Tailscale is not running: \(.BackendState)")
  else
    "| Device | Status | SSH via IPv4 | SSH via IPv6 |",
    "|---|---|---|---|",
    (([.Self + {is_self: true}] + ([.Peer[]?] | sort_by(.HostName)))[]
      | (.HostName | gsub("\\|"; "&#124;") | gsub("[\\r\\n]"; " ")) as $name
      | (if .is_self then "\($name), this machine" else $name end) as $device
      | (if .Online then "Online" else "Offline" end) as $online
      | "| \($device) | \($online) | \(ssh_commands(false)) | \(ssh_commands(true)) |")
  end
' <<< "$status"

printf '\nSSH access has not been verified. Each device needs an SSH server and permission to connect. Use ssh username@IP if the remote username differs from your local username.\n'
