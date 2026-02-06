HOME_DIR := $(HOME)
DOTFILES_SRC := ./dotfiles/
DOTFILES_DEST := $(HOME_DIR)/.dotfiles/

.PHONY: copy-local sync-dotfiles-linux sync-dotfiles-macos clean-dsstore bootstrap-collections syntax-check lint check-linux check-macos validate validate-linux validate-macos ssh-linux-vault ssh-macos-vault ssh-linux-vault-file ssh-macos-vault-file

VAULT_PASSWORD_FILE ?= .vault_pass

copy-local:
	cp -r $(DOTFILES_DEST)* $(DOTFILES_SRC)

bootstrap-collections:
	ansible-galaxy collection install -r requirements.yml

syntax-check:
	ansible-playbook -i localhost, local-linux.yml --syntax-check
	ansible-playbook -i localhost, local-macos.yml --syntax-check

lint:
	python -m ansiblelint local-linux.yml local-macos.yml tasks/*.yml

check-linux:
	ansible-playbook -i localhost, local-linux.yml --check --diff --skip-tags "ssh"

check-macos:
	ansible-playbook -i localhost, local-macos.yml --check --diff --skip-tags "ssh"

validate: bootstrap-collections syntax-check lint

validate-linux: validate check-linux

validate-macos: validate check-macos

ssh-linux-vault:
	ansible-playbook -i localhost, local-linux.yml --tags "ssh" --ask-vault-pass

ssh-macos-vault:
	ansible-playbook -i localhost, local-macos.yml --tags "ssh" --ask-vault-pass

ssh-linux-vault-file:
	ansible-playbook -i localhost, local-linux.yml --tags "ssh" --vault-password-file "$(VAULT_PASSWORD_FILE)"

ssh-macos-vault-file:
	ansible-playbook -i localhost, local-macos.yml --tags "ssh" --vault-password-file "$(VAULT_PASSWORD_FILE)"

sync-dotfiles-linux:
	ansible-playbook -i localhost, local-linux.yml --tags "dotfiles" --ask-become-pass

sync-dotfiles-macos:
	ansible-playbook -i localhost, local-macos.yml --tags "dotfiles" --skip-tags "linux-only" --ask-become-pass

# Target: remove all .DS_Store files recursively
clean-dsstore:
	find . -name ".DS_Store" -type f -delete
	@echo "Cleaned up all .DS_Store files."
