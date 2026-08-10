# Setup Prerequisites

This repository supports two environments:

- Windows through WSL 2 and Ubuntu (`local-linux.yml`)
- macOS natively (`local-macos.yml`)

WSL is a Windows feature; it is not used on macOS.

## Before starting

- Have reliable internet access. The playbooks download packages, releases, Docker, Rust tools, AI CLIs, and other binaries.
- Use an account with `sudo` access on Linux or administrator access on macOS.
- Back up existing shell and configuration files before running the dotfiles setup on a non-empty machine.
- Clone the repository into the Linux filesystem on WSL, such as `~/src/ansible`, rather than under `/mnt/c`.
- The Linux tasks currently assume an x86_64/AMD64 environment for several downloaded binaries.

## Windows and WSL 2

### 1. Install WSL

Run these commands from **Administrator PowerShell**:

```powershell
wsl --install -d Ubuntu
wsl --update
```

Restart Windows if prompted. Open Ubuntu and create your Linux username and password.

### 2. Clone and run the setup

Git is needed before the repository can be cloned. Inside Ubuntu:

```bash
sudo apt update
sudo apt install -y git

git clone <repository-url> ~/src/ansible
cd ~/src/ansible
bash run-linux.sh
```

`run-linux.sh` installs the remaining bootstrap packages (`curl`, `rsync`, and `ca-certificates`), Ansible, the required Ansible collections, and the Linux playbook.

The Linux playbook also enables systemd in `/etc/wsl.conf`, installs Docker inside WSL, configures the shell, and installs the repository dotfiles. Restart WSL afterwards from PowerShell so systemd and Docker changes take effect:

```powershell
wsl --shutdown
```

Then reopen Ubuntu.

### WSL notes

- CUDA installation is disabled by default because it downloads several gigabytes. Enable it with `INSTALL_CUDA_WSL=true bash run-linux.sh`, or pass `--extra-vars install_cuda_wsl=true` when running the playbook directly.
- The playbook installs Docker Engine inside WSL. Decide whether to use that or Docker Desktop integration rather than configuring both unintentionally.
- SSH setup is skipped by `run-linux.sh`. Configure SSH separately when needed.
- On Ubuntu 25.10 and later the default `sudo` is `sudo-rs`, whose password prompt breaks Ansible's `become` detection (it fails with `Timed out waiting for become success or become password prompt`). `run-linux.sh` works around this by installing classic sudo and setting `ANSIBLE_BECOME_EXE=sudo.ws`; do the same when running `ansible-playbook` by hand.
- To copy selected configuration to native Windows applications after the WSL setup, run:

```bash
make sync-dotfiles-windows
```

## macOS

WSL is not required. Use the native macOS setup.

### 1. Install Apple command-line tools

```bash
xcode-select --install
```

This provides Git, which `run-macos.sh` checks before continuing.

### 2. Clone and run the setup

```bash
git clone <repository-url> ~/src/ansible
cd ~/src/ansible
bash run-macos.sh
```

The script installs Homebrew and Ansible if they are missing, installs the required collection, and runs the macOS playbook. The playbook installs a broad set of Homebrew packages, GUI applications, fonts, development tools, and dotfiles, so expect administrator-password prompts and application permission prompts.

## SSH and secrets

The bootstrap scripts intentionally skip SSH key copying. For an existing local key, set its path before running the SSH-tagged playbook:

```bash
export ANSIBLE_SOURCE_SSH_KEY="$HOME/.ssh/id_ed25519"
```

For the repository's vaulted SSH files, use the appropriate Make target and keep the vault password private. Never add an unencrypted private key or other local secrets to the repository.
