#!/bin/bash

# Install Ansible
sudo apt update
sudo apt install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Run the test for now
# ansible-playbook test.yml

# Run Ansible playbook
ansible-playbook local-linux.yml --ask-become-pass --skip-tags "macos-only,ssh"
