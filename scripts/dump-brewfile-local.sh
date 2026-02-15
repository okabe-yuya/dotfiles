#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
BREWFILE="$DOTFILES/Brewfile"
BREWFILE_LOCAL="$DOTFILES/Brewfile.local"

if [ ! -f "$BREWFILE" ]; then
    echo "Error: $BREWFILE が見つかりません" >&2
    exit 1
fi

# 1. 現在インストールされている全パッケージをダンプ
all_dump=$(brew bundle dump --file=-)

# 2. Brewfile に登録済みのエントリを除外して Brewfile.local に出力
# Brewfile からコメント・空行を除いた有効行を取得
brewfile_entries=$(grep -v '^\s*#' "$BREWFILE" | grep -v '^\s*$' | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')

filtered=""
while IFS= read -r line; do
    # Brewfile に同一行があればスキップ
    if echo "$brewfile_entries" | grep -qxF "$line"; then
        continue
    fi
    # VSCode関連 (cask, 拡張機能) はスキップ
    if echo "$line" | grep -qiE 'visual-studio-code|vscode'; then
        continue
    fi
    filtered+="$line"$'\n'
done <<< "$all_dump"

# 末尾の空行を除去して書き出し
echo -n "$filtered" > "$BREWFILE_LOCAL"

echo "Brewfile.local を生成しました: $BREWFILE_LOCAL"
echo "$(grep -c '' "$BREWFILE_LOCAL") 件のエントリが記録されました"
