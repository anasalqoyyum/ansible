# Personal Development Environment Setup

Ansible playbooks for bootstrapping a personal setup on:

- WSL/Linux (`local-linux.yml`)
- macOS (`local-macos.yml`)

## Quick Start

- Linux/WSL: `bash run-linux.sh`
- macOS: `bash run-macos.sh`

Both scripts install Ansible (if missing), install required collections from `requirements.yml`, and run the matching playbook.

## New Machine How-To

Read [PREREQUISITES.md](PREREQUISITES.md) before setting up a new machine.

### Windows + WSL 2

From Administrator PowerShell:

```powershell
wsl --install -d Ubuntu
wsl --update
```

After restarting Windows, open Ubuntu, create your Linux user, then clone and run the setup:

```bash
sudo apt update
sudo apt install -y git
git clone <repository-url> ~/src/ansible
cd ~/src/ansible
bash run-linux.sh
```

Restart WSL afterwards with `wsl --shutdown` from PowerShell.

### macOS

Install the Apple command-line tools, then clone and run the native setup:

```bash
xcode-select --install
git clone <repository-url> ~/src/ansible
cd ~/src/ansible
bash run-macos.sh
```

## Validation Workflow

Run these before applying bigger changes:

- `make bootstrap-collections`
- `make syntax-check`
- `make lint`

The lint target uses `uvx` to run `ansible-lint` without a manual installation.

Optional dry-run checks:

- Linux/WSL: `make check-linux`
- macOS: `make check-macos`

Convenience targets:

- Linux validation bundle: `make validate-linux`
- macOS validation bundle: `make validate-macos`

Optional WSL OpenSSH server setup:

```bash
INSTALL_OPENSSH_SERVER_WSL=true bash run-linux.sh
```

This installs `openssh-server`, enables `ssh.socket`, and verifies that port 22 is listening. It is disabled by default.

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

## Dotfiles sync helpers

- Apply dotfiles on Linux: `make sync-dotfiles-linux`
- Apply dotfiles on macOS: `make sync-dotfiles-macos`
- Copy dotfiles to Windows: `make sync-dotfiles-windows`
- Sync local dotfiles back into this repo: `make copy-local`
- Test sync and migration behavior: `make test-dotfiles`
- Clean `.DS_Store` files: `make clean-dsstore`

Linux and macOS use Stow with `--no-folding`. Directories such as `~/.pi/agent`
remain real directories, and only managed files link into `~/.dotfiles`. New auth
files, caches, and sessions stay in your home directory, outside the repo sync.

Before syncing, the playbook moves local-only entries and known runtime state out
of any legacy Stow directory links. It preserves file permissions and refuses to
overwrite unrelated local files. Check mode previews these moves without changing
files. On this first
migration, entries absent from the repo are kept as local state, including any
previously removed configuration files. Stop apps that write to these directories
before the first sync.

Local `node_modules` under managed code stays in `~/.dotfiles` so imports through
symlinked code still resolve. Rsync protects those dependencies from deletion.
Windows uses file copies rather than Stow and keeps destination-only files, so
removed repo files must be cleaned up manually there.

`dotfiles/.sync-exclude` lists runtime paths excluded from both forward sync and
`copy-local`, including Pi credentials, sessions, and caches. This also prevents
old ignored runtime files in the repo directory from being copied back into your
home. New runtime files live outside `~/.dotfiles` and its copy source.

## Reference

- WSL setup docs: https://learn.microsoft.com/en-us/windows/wsl/install
