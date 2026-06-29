.PHONY: all setup zsh tmux nvim git ghostty claude cage brew

# 何も指定しなければ all (= setup + brew)
all: setup brew

# シンボリックリンクのセットアップだけ (brew は分離)
setup: zsh tmux nvim git ghostty claude cage

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
	@$(call unlink_if_file_exists,~/.gitignore)
	ln -sv ~/dotfiles/git/.gitignore ~/.gitignore

GHOSTTY_CONFIG = "$(HOME)/Library/Application Support/com.mitchellh.ghostty/config"

ghostty:
	@$(call unlink_if_file_exists,$(GHOSTTY_CONFIG))
	ln -sv ~/dotfiles/ghostty/config $(GHOSTTY_CONFIG)

claude:
	scripts/make-claude.sh

CAGE_CONFIG = $(HOME)/.config/cage/presets.yml

cage:
	@mkdir -p $(dir $(CAGE_CONFIG))
	@$(call unlink_if_file_exists,$(CAGE_CONFIG))
	ln -sv ~/dotfiles/cage/presets.yml $(CAGE_CONFIG)

brew:
	brew bundle --file=~/dotfiles/Brewfile
	@if [ -f ~/dotfiles/Brewfile.local ]; then \
		brew bundle --file=~/dotfiles/Brewfile.local; \
	fi

