# Personal Development Environment Setup

Ansible playbooks for bootstrapping a personal setup on:

- WSL/Linux (`local-linux.yml`)
- macOS (`local-macos.yml`)

## Quick Start

- Linux/WSL: `bash run-linux.sh`
- macOS: `bash run-macos.sh`

Both scripts install Ansible (if missing), install required collections from `requirements.yml`, and run the matching playbook.

## Validation Workflow

Run these before applying bigger changes:

- `make bootstrap-collections`
- `make syntax-check`
- `make lint`

If lint is missing locally, install it with `python -m pip install ansible-lint`.

Optional dry-run checks:

- Linux/WSL: `make check-linux`
- macOS: `make check-macos`

Convenience targets:

- Linux validation bundle: `make validate-linux`
- macOS validation bundle: `make validate-macos`

## Useful Playbook Commands

- Linux dotfiles only: `ansible-playbook -i localhost, local-linux.yml --tags "dotfiles" --ask-become-pass`
- macOS dotfiles only: `ansible-playbook -i localhost, local-macos.yml --tags "dotfiles" --ask-become-pass`
- Skip SSH copy tasks: add `--skip-tags "ssh"`

## Security Notes

- Do not commit private keys or local secrets.
- SSH key copy is optional and controlled by tag `ssh`.
- To provide a custom key path, set:

```bash
export ANSIBLE_SOURCE_SSH_KEY="$HOME/.ssh/id_ed25519"
```

If the key source path does not exist, the SSH key copy step is skipped with a warning.

## Repo Structure

- Main playbooks: `local-linux.yml`, `local-macos.yml`
- Tasks: `tasks/*.yml`
- Dotfiles source: `dotfiles/`
- Validation and helper commands: `Makefile`

## Dotfiles Sync Helpers

- Sync local dotfiles back into this repo: `make copy-local`
- Clean `.DS_Store` files: `make clean-dsstore`

## Reference

- WSL setup docs: https://learn.microsoft.com/en-us/windows/wsl/install
