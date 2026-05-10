#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

windows_user="${WINDOWS_USER:-}"
if [[ -z "$windows_user" ]]; then
  if command -v cmd.exe >/dev/null 2>&1; then
    windows_user="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r' | tail -n 1)"
  fi
fi

if [[ -z "$windows_user" ]]; then
  echo "Could not detect the Windows user. Set WINDOWS_USER, for example:" >&2
  echo "  WINDOWS_USER=doubl $0" >&2
  exit 1
fi

windows_home="/mnt/c/Users/$windows_user"
if [[ ! -d "$windows_home" ]]; then
  echo "Windows home directory does not exist: $windows_home" >&2
  echo "Set WINDOWS_USER if detection picked the wrong account." >&2
  exit 1
fi

validate_windows_target() {
  local name="$1"
  local target="$2"
  local expected_prefix="$windows_home/"

  case "$target" in
  "$expected_prefix"*) ;;
  *)
    echo "Refusing to sync $name to unexpected target: $target" >&2
    echo "Expected target to be under: $windows_home" >&2
    exit 1
    ;;
  esac
}

sync_dir() {
  local name="$1"
  local source="$2"
  local target="$3"

  if [[ ! -d "$source" ]]; then
    echo "Missing source for $name: $source" >&2
    exit 1
  fi

  validate_windows_target "$name" "$target"

  mkdir -p "$target"
  echo "Syncing $name: $source -> $target"
  rsync -aL --delete --filter=':- .gitignore' "$source/" "$target/"
}

sync_file() {
  local name="$1"
  local source="$2"
  local target="$3"

  if [[ ! -f "$source" ]]; then
    echo "Missing source for $name: $source" >&2
    exit 1
  fi

  validate_windows_target "$name" "$target"

  mkdir -p "$(dirname "$target")"
  echo "Syncing $name: $source -> $target"
  install -m 0644 "$source" "$target"
}

sync_dir "agents" "$repo_root/dotfiles/agents/.agents" "$windows_home/.agents"
sync_file "codex agents" "$repo_root/dotfiles/agents/.agents/AGENTS.md" "$windows_home/.codex/AGENTS.md"
sync_dir "mise" "$repo_root/dotfiles/mise/.config/mise" "$windows_home/.config/mise"
sync_dir "nvim" "$repo_root/dotfiles/nvim/.config/nvim" "$windows_home/AppData/Local/nvim"
sync_dir "pi" "$repo_root/dotfiles/pi/.pi" "$windows_home/.pi"
sync_dir "opencode" "$repo_root/dotfiles/opencode/.config/opencode" "$windows_home/.config/opencode"
sync_dir "zed" "$repo_root/dotfiles/zed/.config/zed" "$windows_home/AppData/Roaming/Zed"
sync_file "whkdrc" "$repo_root/dotfiles/komorebi/.config/whkdrc" "$windows_home/.config/whkdrc"
sync_file "komorebi" "$repo_root/dotfiles/komorebi/.config/komorebi/komorebi.json" "$windows_home/.config/komorebi/komorebi.json"
sync_file "komorebi applications" "$repo_root/dotfiles/komorebi/.config/komorebi/applications.win.json" "$windows_home/.config/komorebi/applications.json"
sync_file "komorebi bar" "$repo_root/dotfiles/komorebi/.config/komorebi/komorebi.bar.win.json" "$windows_home/.config/komorebi/komorebi.bar.json"

echo "Done."
