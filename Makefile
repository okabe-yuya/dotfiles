.PHONY: zsh tmux nvim

unlink_if_file_exists = \
	if [ -e $1 ]; then \
		unlink $1; \
	fi

zsh:
	@$(call unlink_if_file_exists,~/.zshrc)
	ln -sv ~/dotfiles/zsh/.zshrc ~/.zshrc

tmux:
	@$(call unlink_if_file_exists,~/.tmux_conf)
	ln -sv ./tmux/.tmux_conf ~/.tmux_conf

nvim:
	@$(call unlink_if_file_exists,~/.config/nvim/init.vim)
	ln -sv ~/dotfiles/nvim/init.vim ~/.config/nvim/init.vim
