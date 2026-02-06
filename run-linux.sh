#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v ansible >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y software-properties-common
  sudo apt-add-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
fi

ansible-galaxy collection install -r requirements.yml
ansible-playbook -i localhost, local-linux.yml --ask-become-pass --skip-tags "macos-only,ssh"
