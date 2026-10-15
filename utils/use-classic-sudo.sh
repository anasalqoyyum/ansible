# shellcheck shell=sh
# Source before running ansible-playbook with --ask-become-pass on Linux.
#
# sudo-rs (default sudo on Ubuntu 25.10+) nests sudo's -p prompt instead of
# replacing it, so Ansible never matches its become prompt and times out.
# https://github.com/ansible/ansible/issues/85837
if sudo --version 2>&1 | grep -qi 'sudo-rs'; then
  command -v sudo.ws >/dev/null 2>&1 || sudo apt install -y sudo

  if ! command -v sudo.ws >/dev/null 2>&1; then
    echo "sudo-rs breaks Ansible's become prompt and classic sudo (sudo.ws) is unavailable." >&2
    exit 1
  fi

  ANSIBLE_BECOME_EXE="$(command -v sudo.ws)"
  export ANSIBLE_BECOME_EXE
fi
