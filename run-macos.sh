#!/bin/bash

# Check command line tools and git
if ! command -v git &>/dev/null; then
  echo "Git is not installed. Please install command line tools first."
  exit 1
fi
git --version

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon (M1/M2) Macs
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    # For Intel Macs
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >>$HOME/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew is already installed"
fi

# Verify Homebrew installation
if ! command -v brew &>/dev/null; then
  echo "Homebrew installation failed"
  exit 1
fi

# Install ansible if not already installed
if ! command -v ansible &>/dev/null; then
  echo "Installing Ansible..."
  brew install ansible
else
  echo "Ansible is already installed"
fi

# Run the test for now
# ansible-playbook test.yml

# Run Ansible playbook
ansible-playbook local-macos.yml --ask-become-pass --skip-tags "linux-only,git-ab,ssh"
