.PHONY: all setup zsh tmux nvim git ghostty claude brew kotlin-lsp lint

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
setup: zsh tmux nvim git ghostty claude
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

brew:
	$(call section,brew)
	@brew bundle --file=$(HOME)/dotfiles/Brewfile
	@if [ -f $(HOME)/dotfiles/Brewfile.local ]; then \
		brew bundle --file=$(HOME)/dotfiles/Brewfile.local; \
	fi

# kotlin-lsp の最新ビルドへの貼り替え (約30日で失効するため都度実行する)
# 360MB 級の DL を伴うため setup には含めず、必要なときだけ叩く
# 強制再取得: make kotlin-lsp ARGS=--force
kotlin-lsp:
	$(call section,kotlin-lsp)
	@scripts/kotlin-lsp-update.sh $(ARGS)

# scripts/ 配下のシェルスクリプトを静的検査する (bash -n + shellcheck)
# shellcheck 未導入なら bash -n のみに縮退する
lint:
	$(call section,lint)
	@for f in scripts/*.sh; do \
		bash -n "$$f" && printf "  $(G)✓$(R) bash -n %s\n" "$$f"; \
	done
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh && printf "  $(G)✓$(R) shellcheck passed\n"; \
	else \
		printf "  (shellcheck 未導入: brew install shellcheck で有効化)\n"; \
	fi
