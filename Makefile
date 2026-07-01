HOME_DIR := $(HOME)
DOTFILES_SRC := ./dotfiles/
DOTFILES_DEST := $(HOME_DIR)/.dotfiles/
DETECTED_WINDOWS_USER := $(shell if command -v cmd.exe >/dev/null 2>&1; then cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r' | tail -n 1; fi)
WINDOWS_USER := $(or $(WINDOWS_USER),$(DETECTED_WINDOWS_USER))
WINDOWS_HOME := /mnt/c/Users/$(WINDOWS_USER)
ZED_WINDOWS_DIR ?= $(WINDOWS_HOME)/AppData/Roaming/Zed
ZED_DOTFILES_DIR := ./dotfiles/zed/.config/zed

.PHONY: copy-local sync-dotfiles-linux sync-dotfiles-macos sync-dotfiles-windows sync-zed-windows clean-dsstore bootstrap-collections syntax-check lint check-linux check-macos validate validate-linux validate-macos ssh-linux-vault ssh-macos-vault ssh-linux-vault-file ssh-macos-vault-file

VAULT_PASSWORD_FILE ?= .vault_pass
COPY_LOCAL_EXCLUDE ?= .stow.log

copy-local:
	rsync -a --exclude='$(COPY_LOCAL_EXCLUDE)' --exclude='node_modules/' "$(DOTFILES_DEST)" "$(DOTFILES_SRC)"

bootstrap-collections:
	ansible-galaxy collection install -r requirements.yml

syntax-check:
	ansible-playbook local-linux.yml --syntax-check
	ansible-playbook local-macos.yml --syntax-check

lint:
	python -m ansiblelint local-linux.yml local-macos.yml tasks/*.yml

check-linux:
	ansible-playbook local-linux.yml --check --diff --skip-tags "ssh"

check-macos:
	ansible-playbook local-macos.yml --check --diff --skip-tags "ssh"

validate: bootstrap-collections syntax-check lint

validate-linux: validate check-linux

validate-macos: validate check-macos

ssh-linux-vault:
	ansible-playbook local-linux.yml --tags "ssh" --ask-vault-pass

ssh-macos-vault:
	ansible-playbook local-macos.yml --tags "ssh" --ask-vault-pass

ssh-linux-vault-file:
	ansible-playbook local-linux.yml --tags "ssh" --vault-password-file "$(VAULT_PASSWORD_FILE)"

ssh-macos-vault-file:
	ansible-playbook local-macos.yml --tags "ssh" --vault-password-file "$(VAULT_PASSWORD_FILE)"

sync-dotfiles-linux:
	ansible-playbook local-linux.yml --tags "dotfiles" --ask-become-pass

sync-dotfiles-macos:
	ansible-playbook local-macos.yml --tags "dotfiles" --skip-tags "linux-only" --ask-become-pass

sync-dotfiles-windows:
	./utils/sync-dotfiles-to-windows.sh

sync-zed-windows:
	@if [ -z "$(WINDOWS_USER)" ]; then \
		echo "Could not detect the Windows user. Set WINDOWS_USER, for example:" >&2; \
		echo "  WINDOWS_USER=doubl make sync-zed-windows" >&2; \
		exit 1; \
	fi
	@if [ ! -d "$(WINDOWS_HOME)" ]; then \
		echo "Windows home directory does not exist: $(WINDOWS_HOME)" >&2; \
		echo "Set WINDOWS_USER if detection picked the wrong account." >&2; \
		exit 1; \
	fi
	mkdir -p "$(ZED_DOTFILES_DIR)"
	install -m 0644 "$(ZED_WINDOWS_DIR)/keymap.json" "$(ZED_DOTFILES_DIR)/keymap.json"
	install -m 0644 "$(ZED_WINDOWS_DIR)/settings.json" "$(ZED_DOTFILES_DIR)/settings.json"

# Target: remove all .DS_Store files recursively
clean-dsstore:
	find . -name ".DS_Store" -type f -delete
	@echo "Cleaned up all .DS_Store files."
