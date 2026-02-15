.PHONY: zsh tmux nvim git ghostty claude brew 

unlink_if_file_exists = \
	if [ -e $1 ]; then \
		unlink $1; \
	fi

zsh:
	@$(call unlink_if_file_exists,~/.zshrc)
	ln -sv ~/dotfiles/zsh/.zshrc ~/.zshrc

tmux:
	@$(call unlink_if_file_exists,~/.tmux.conf)
	ln -sv ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf

nvim:
	scripts/make-nvim.sh

git:
	@$(call unlink_if_file_exists,~/.gitconfig)
	ln -sv ~/dotfiles/git/.gitconfig ~/.gitconfig

GHOSTTY_CONFIG = "$(HOME)/Library/Application Support/com.mitchellh.ghostty/config"

ghostty:
	@$(call unlink_if_file_exists,$(GHOSTTY_CONFIG))
	ln -sv ~/dotfiles/ghostty/config $(GHOSTTY_CONFIG)

claude:
	scripts/make-claude.sh

brew:
	brew bundle --file=~/dotfiles/Brewfile
	@if [ -f ~/dotfiles/Brewfile.local ]; then \
		brew bundle --file=~/dotfiles/Brewfile.local; \
	fi

