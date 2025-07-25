# AGENTS.md - Development Environment Setup with Ansible

## Build/Test Commands
- **Run Linux setup**: `bash run-linux.sh` (installs Ansible, runs playbook with `--ask-become-pass --skip-tags "macos-only,git-ab,ssh"`)
- **Run macOS setup**: `bash run-macos.sh` (installs Homebrew/Ansible, runs playbook with `--ask-become-pass --skip-tags "linux-only,git-ab,ssh"`)
- **Test playbook**: `ansible-playbook test.yml` (basic connectivity test)
- **Run specific tags**: `ansible-playbook local-{linux|macos}.yml --tags "dotfiles" --ask-become-pass`
- **Sync dotfiles**: `make sync-dotfiles-{linux|macos}` or `make sync-dotfiles-local`

## Project Structure
This is an Ansible-based personal development environment setup repository that configures dotfiles, tools, and development environments for both Linux (WSL) and macOS systems.

## Code Style & Conventions
- **YAML files**: Use 2-space indentation, lowercase names with hyphens
- **Task naming**: Descriptive names in sentence case (e.g., "Install Core Packages")
- **Tags**: Use lowercase with hyphens for grouping (install, core, linux-only, macos-only)
- **Variables**: Use snake_case for variable names
- **File organization**: Tasks in `tasks/` directory, main playbooks in root
- **Conditionals**: Use `when:` clauses for OS-specific tasks
- **Privileges**: Use `become: true` for sudo operations
- **Error handling**: Use `ignore_errors: true` for non-critical checks

## Key Components
- Main playbooks: `local-linux.yml`, `local-macos.yml`
- Task files in `tasks/` directory for modular setup
- Dotfiles managed in `dotfiles/` with stow-like structure
- Shell scripts for initial setup and dependency installation