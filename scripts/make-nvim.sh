#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob  # マッチ無しの glob を空配列にする (リテラル `*` の symlink を防ぐ)

DOTFILES="$HOME/dotfiles/nvim"
NVIMCONF="$HOME/.config/nvim"

GREEN=$'\033[32m'
RESET=$'\033[0m'

link() {
    local src="$1"
    local dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        rm -rf "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    printf "  ${GREEN}✓${RESET} %s\n" "$dst"
}

# ディレクトリ作成
mkdir -p "$NVIMCONF"/{lua,luasnippets}

# init.lua
link "$DOTFILES/init.lua" "$NVIMCONF/init.lua"

# ftplugin 配下 (ディレクトリが存在し、ファイルがある場合のみ)
if [ -d "$DOTFILES/ftplugin" ]; then
    for f in "$DOTFILES/ftplugin/"*; do
        link "$f" "$NVIMCONF/ftplugin/$(basename "$f")"
    done
fi

# luasnippets 配下
for f in "$DOTFILES/luasnippets/"*; do
    link "$f" "$NVIMCONF/luasnippets/$(basename "$f")"
done

# lua 以下を再帰的にリンク
find "$DOTFILES/lua" -type d | while read -r dir; do
    rel="${dir#$DOTFILES/}"
    mkdir -p "$NVIMCONF/$rel"
done

find "$DOTFILES/lua" -type f | while read -r file; do
    rel="${file#$DOTFILES/}"
    link "$file" "$NVIMCONF/$rel"
done
