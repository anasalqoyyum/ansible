#!/bin/bash

# Check command line tools and git
git -v

# Run the test for now
# ansible-playbook test.yml

# Run Ansible playbook
ansible-playbook local-macos.yml --ask-become-pass --skip-tags "linux-only,git-ab,ssh"
