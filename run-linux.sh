#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

sudo apt update
sudo apt install -y git curl rsync ca-certificates ansible ansible-core

# shellcheck source=utils/use-classic-sudo.sh
source utils/use-classic-sudo.sh

ansible-galaxy collection install -r requirements.yml
ansible-playbook local-linux.yml \
  --ask-become-pass \
  --skip-tags "macos-only,ssh" \
  --extra-vars "install_cuda_wsl=${INSTALL_CUDA_WSL:-false}" \
  --extra-vars "install_openssh_server_wsl=${INSTALL_OPENSSH_SERVER_WSL:-false}" \
  "$@"
