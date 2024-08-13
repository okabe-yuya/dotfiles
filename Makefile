.PHONY: zsh tmux starship

zsh:
	unlink ~/.zshrc
	ln -sv ~/dotfiles/zsh/.zshrc ~/.zshrc

tmux:
	unlink ~/.tmux_conf
	ln -sv ./tmux/.tmux_conf ~/.tmux_conf

starship:
	unlink ~/.config/starship/starship.toml
	ln -sv ./starship/starship.toml ~/.config/starship/starship.toml

