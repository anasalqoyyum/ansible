#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your development user, not root or sudo." >&2
  exit 1
fi
# shellcheck source=/dev/null
source /etc/os-release
if [[ $ID != ubuntu || $VERSION_ID != 26.04 ]] || grep -qi microsoft /proc/sys/kernel/osrelease; then
  echo "The devbox profile requires native Ubuntu Desktop 26.04 LTS." >&2
  exit 1
fi

sudo apt update
sudo apt install -y git curl rsync ca-certificates
if ! command -v ansible-playbook >/dev/null 2>&1; then
  sudo apt install -y software-properties-common
  sudo apt-add-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
fi

# shellcheck source=utils/use-classic-sudo.sh
source utils/use-classic-sudo.sh

ansible-galaxy collection install -r requirements.yml
ansible-playbook local-devbox.yml --ask-become-pass --skip-tags "macos-only,ssh" "$@"
