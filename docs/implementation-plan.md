# Ansible Repo Improvement Plan

## Goals

- Improve setup safety for macOS and WSL/Linux.
- Make runs more repeatable with basic validation checks.
- Keep maintenance lightweight for a personal environment repo.

## Current Gaps

- Secret hygiene risk: local SSH key paths can exist in repo scope.
- Validation is manual and inconsistent across environments.
- Several tasks use shell commands where module-based idempotency is better.
- Collection dependencies were implicit instead of explicitly managed.
- Some task paths were defined but not wired into main playbooks.

## What Was Implemented

### 1) Security and Reproducibility Quick Wins

- Hardened ignore rules in `.gitignore`:
  - `.ssh/`, key file extensions, `.env*`, vault pass files.
  - Ansible local artifacts (`*.retry`, `.ansible/`).
- Added collection pinning in `requirements.yml`:
  - `community.general`
  - `ansible.posix`
- Added `ansible.cfg` baseline defaults for local execution consistency.

### 2) Safer Bootstrap Scripts

- Updated `run-linux.sh` and `run-macos.sh`:
  - enabled strict mode (`set -euo pipefail`)
  - made script directory explicit
  - install collections before playbook run
  - avoid duplicate profile edits in macOS bootstrap path

### 3) Playbook Safety and Task Wiring

- Added OS assertions in:
  - `local-linux.yml`
  - `local-macos.yml`
- Added optional task imports that were previously orphaned:
  - `tasks/node-setup.yml` (both playbooks)
  - `tasks/cuda-wsl-setup.yml` (Linux playbook, WSL-guarded)
- Added WSL guard for `conf/wsl.conf` copy in Linux pre-tasks.

### 4) Idempotency and Module-First Improvements

- `tasks/ssh.yml`:
  - source file `stat` checks before copying keys/config
  - skip with clear message if key path does not exist
  - private key copy marked `no_log: true`
- `tasks/dotfiles.yml`:
  - separate stow install paths for Linux (`apt`) and macOS (`homebrew`)
  - replaced shell cd usage with `command` + `chdir`
- `tasks/docker-setup.yml`:
  - user group handling switched to `user` module
  - Docker installer command made create-guarded
  - iptables command made non-fatal and non-changing by default
- `tasks/win32yank-setup.yml`:
  - replaced shell extraction/move with `unarchive` + `copy`
  - made tmux config blocks explicitly managed with markers
- `tasks/zsh-setup.yml`:
  - switched shell-changing flow to `user` module
- `tasks/core-brew-setup.yml`:
  - converted package lists to structured YAML arrays
  - replaced font shell commands with `homebrew_cask` module

### 5) Validation Workflow Added

- New `Makefile` targets:
  - `bootstrap-collections`
  - `syntax-check`
  - `lint`
  - `check-linux`
  - `check-macos`
  - `validate`, `validate-linux`, `validate-macos`

## Dotfiles Review Suggestions

These are recommendations to consider next; not all are implemented yet.

### zsh (`dotfiles/zsh/.zshrc`)

- Split the file into modular source files (`aliases.zsh`, `functions.zsh`, `env.zsh`, `bindings.zsh`) to reduce startup and maintenance complexity.
- Replace destructive aliases like `yolo`/`nuke` with safer functions that prompt for confirmation or run a dry-run first.
- Move expensive command pipelines in functions (`oil`, session pickers) behind lazy checks (`command -v`) to avoid failures on fresh systems.

### tmux (`dotfiles/tmux/.tmux.conf`)

- Keep one clipboard command source of truth to avoid drift between static tmux config and Ansible-injected WSL overrides.
- Add OS-aware include files (`.tmux.macos.conf`, `.tmux.wsl.conf`) and source conditionally.

### prompt + terminal

- `dotfiles/starship/.config/starship.toml`: consider adding a short `jobs` and `status` segment for long-running command context.
- `dotfiles/alacritty/.config/alacritty/alacritty.yml` and `dotfiles/ghostty/.config/ghostty/config`: keep font family aligned in one shared variable or documented convention to avoid visual drift.

## Suggested Next Steps

1. Add lightweight CI to run `make syntax-check` and `make lint` on pull requests.
2. Move host-specific values to vars files (`vars/common.yml`, `vars/linux.yml`, `vars/macos.yml`).
3. Replace remaining shell-heavy Rust tool installation tasks with loop-driven module or guarded command patterns.
