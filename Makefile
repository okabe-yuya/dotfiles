.PHONY: zsh tmux nvim git vscode-key-sync

unlink_if_file_exists = \
	if [ -e $1 ]; then \
		unlink $1; \
	fi

zsh:
	@$(call unlink_if_file_exists,~/.zshrc)
	ln -sv ~/dotfiles/zsh/.zshrc ~/.zshrc

tmux:
	@$(call unlink_if_file_exists,~/.tmux.conf)
	ln -sv ./dotfiles/tmux/.tmux.conf ~/.tmux.conf

nvim:
	@$(call unlink_if_file_exists,~/.config/nvim/init.vim)
	ln -sv ~/dotfiles/nvim/init.vim ~/.config/nvim/init.vim
	mkdir -p ~/.config/nvim/ftplugin
	cp ~/dotfiles/nvim/ftplugin/* ~/.config/nvim/ftplugin/

git:
	@$(call unlink_if_file_exists,~/.gitconfig)
	ln -sv ~/dotfiles/git/.gitconfig ~/.gitconfig

# VSCode keybindings auto-sync Makefile

SRC = "$(HOME)/Library/Application Support/Code/User/keybindings.json"
DEST = "$(HOME)/dotfiles/vscode/keybindings.json"
GIT_DIR = "$(HOME)/dotfiles"
COMMIT_MSG = "Update keybindings.json from VSCode at $(shell date '+%Y-%m-%d %H:%M:%S')"

vscode-key-sync:
	@cp -f $(SRC) $(DEST) 2>/dev/null || true
	@read -p "📝 Commit and push changes? (y/n): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		cd $(GIT_DIR) && \
		git add $(DEST); \
		if git diff --cached --quiet; then \
			echo "⚠️ Nothing to commit"; \
			exit 0; \
		fi; \
		git commit -m $(COMMIT_MSG); \
		git push && echo "🚀 Changes committed and pushed!"; \
	else \
		echo "❌ Commit/push canceled."; \
	fi
