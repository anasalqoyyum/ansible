HOME_DIR := $(HOME)
DOTFILES_SRC := ./dotfiles/
DOTFILES_DEST := $(HOME_DIR)/.dotfiles/

.PHONY: sync-dotfiles-local

sync-dotfiles-local:
	cp -r $(DOTFILES_DEST)* $(DOTFILES_SRC)

sync-dotfiles-linux:
	ansible-playbook local-linux.yml --tags "dotfiles" --ask-become-pass

sync-dotfiles-macos:
	ansible-playbook local-macos.yml --tags "dotfiles" --skip-tags "linux-only" --ask-become-pass
