#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

sudo apt update
sudo apt install -y git curl rsync ca-certificates

if ! command -v ansible >/dev/null 2>&1; then
  sudo apt install -y software-properties-common
  sudo apt-add-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
fi

# sudo-rs (default sudo on Ubuntu 25.10+) nests sudo's -p prompt instead of
# replacing it, so Ansible never matches its become prompt and times out.
# https://github.com/ansible/ansible/issues/85837
if sudo --version 2>&1 | grep -qi 'sudo-rs'; then
  command -v sudo.ws >/dev/null 2>&1 || sudo apt install -y sudo

  if ! command -v sudo.ws >/dev/null 2>&1; then
    echo "sudo-rs breaks Ansible's become prompt and classic sudo (sudo.ws) is unavailable." >&2
    exit 1
  fi

  export ANSIBLE_BECOME_EXE="$(command -v sudo.ws)"
fi

ansible-galaxy collection install -r requirements.yml
ansible-playbook local-linux.yml \
  --ask-become-pass \
  --skip-tags "macos-only,ssh" \
  --extra-vars "install_cuda_wsl=${INSTALL_CUDA_WSL:-false}"
