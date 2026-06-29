.PHONY: all setup zsh tmux nvim git ghostty claude cage brew

# 出力用 ANSI エスケープ
H := \033[1;36m
G := \033[32m
B := \033[1;32m
R := \033[0m

# シンボリックリンクを作成し、結果を一行で表示する
# 使い方: $(call link,<src>,<dst>)
define link
	@if [ -e "$(2)" ] || [ -L "$(2)" ]; then rm -rf "$(2)"; fi
	@mkdir -p "$$(dirname "$(2)")"
	@ln -s "$(1)" "$(2)"
	@printf "  $(G)✓$(R) %s\n" "$(2)"
endef

# セクションヘッダ
define section
	@printf "\n$(H)==> $(1)$(R)\n"
endef

# 何も指定しなければ all (= setup + brew)
all: setup brew

# シンボリックリンクのセットアップだけ (brew は分離)
setup: zsh tmux nvim git ghostty claude cage
	@printf "\n$(B)✨ Setup completed!$(R)\n"

zsh:
	$(call section,zsh)
	$(call link,$(HOME)/dotfiles/zsh/.zshrc,$(HOME)/.zshrc)

tmux:
	$(call section,tmux)
	$(call link,$(HOME)/dotfiles/tmux/.tmux.conf,$(HOME)/.tmux.conf)

nvim:
	$(call section,nvim)
	@scripts/make-nvim.sh

git:
	$(call section,git)
	$(call link,$(HOME)/dotfiles/git/.gitconfig,$(HOME)/.gitconfig)
	$(call link,$(HOME)/dotfiles/git/.gitignore,$(HOME)/.gitignore)

GHOSTTY_CONFIG = $(HOME)/Library/Application Support/com.mitchellh.ghostty/config

ghostty:
	$(call section,ghostty)
	$(call link,$(HOME)/dotfiles/ghostty/config,$(GHOSTTY_CONFIG))

claude:
	$(call section,claude)
	@scripts/make-claude.sh

CAGE_CONFIG = $(HOME)/.config/cage/presets.yml

cage:
	$(call section,cage)
	$(call link,$(HOME)/dotfiles/cage/presets.yml,$(CAGE_CONFIG))

brew:
	$(call section,brew)
	@brew bundle --file=$(HOME)/dotfiles/Brewfile
	@if [ -f $(HOME)/dotfiles/Brewfile.local ]; then \
		brew bundle --file=$(HOME)/dotfiles/Brewfile.local; \
	fi
