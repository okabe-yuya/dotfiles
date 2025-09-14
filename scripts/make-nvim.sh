#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles/nvim"
NVIMCONF="$HOME/.config/nvim"

# ディレクトリ作成
mkdir -p "$NVIMCONF"/{ftplugin,lua,luasnippets}

# init.lua は強制リンク
ln -sfnv "$DOTFILES/init.lua" "$NVIMCONF/init.lua"

# ftplugin 配下をリンク
for f in "$DOTFILES/ftplugin/"*; do
    ln -sfnv "$f" "$NVIMCONF/ftplugin/"
done

# luasnippets 配下をリンク
for f in "$DOTFILES/luasnippets/"*; do
    ln -sfnv "$f" "$NVIMCONF/luasnippets/"
done

# lua 以下を再帰的にリンク
find "$DOTFILES/lua" -type d | while read -r dir; do
    # サブディレクトリを作る
    rel="${dir#$DOTFILES/}"   # DOTFILES 以下の相対パス
    mkdir -p "$NVIMCONF/$rel"
done

find "$DOTFILES/lua" -type f | while read -r file; do
    rel="${file#$DOTFILES/}"  # DOTFILES 以下の相対パス
    ln -sfnv "$file" "$NVIMCONF/$rel"
done


echo "✨Neovim config setup completed."
