HOME_DIR := $(HOME)
DOTFILES_SRC := ./dotfiles/
DOTFILES_DEST := $(HOME_DIR)/.dotfiles/

.PHONY: sync-dotfiles-local

copy-local:
	cp -r $(DOTFILES_DEST)* $(DOTFILES_SRC)

sync-dotfiles-linux:
	ansible-playbook local-linux.yml --tags "dotfiles" --ask-become-pass

sync-dotfiles-macos:
	ansible-playbook local-macos.yml --tags "dotfiles" --skip-tags "linux-only" --ask-become-pass

# Target: remove all .DS_Store files recursively
clean-dsstore:
	find . -name ".DS_Store" -type f -delete
	@echo "🧹 Cleaned up all .DS_Store files."
