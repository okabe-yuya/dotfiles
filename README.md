# dotfiles


## 含まれてるもの

| ディレクトリ | 何の設定か |
|---|---|
| `zsh/` | シェル（peco連携、Git prompt、エイリアスなど） |
| `nvim/` | Neovim（lazy.nvim + LSP + Treesitter） |
| `tmux/` | tmux（Prefix: `Ctrl+Q`、Vim風キーバインド） |
| `git/` | Git（ユーザー設定、push戦略など） |
| `ghostty/` | Ghostty ターミナル（Rose Pineテーマ） |
| `vscode/` | VSCode（Neovim拡張用init.lua、keybindings） |
| `claude/` | Claude Code（コーディングルール、スキル、AIレビューエージェント） |
| `scripts/` | セットアップ用スクリプト |
| `Brewfile` | Homebrewで入れるパッケージ一覧 |

## セットアップ

### 1. Homebrewパッケージのインストール

```sh
brew bundle
```

### 2. 各ツールの設定をシンボリックリンク

```sh
make zsh      # ~/.zshrc
make tmux     # ~/.tmux.conf
make nvim     # ~/.config/nvim/
make git      # ~/.gitconfig
make ghostty  # Ghostty config
make vscode   # VSCode Neovim init.lua
make claude   # Claude Code settings, rules, skills, agents
```

基本的にはシンボリックリンクを貼るだけ。既にファイルがある場合は `unlink` してから貼り直す。

## ざっくり紹介

### Zsh

- `peco` でコマンド履歴（`Ctrl+R`）とディレクトリ移動（`Ctrl+T`）をインタラクティブに
- Gitブランチの状態をプロンプトに表示
- `.zshrc.local` でマシン固有の設定を上書きできる

### Neovim

- Lua ベースの設定。プラグイン管理は lazy.nvim
- LSP、補完（blink.cmp）、ファジーファインダー（Telescope）、ファイラー（Oil.nvim）あたりが中心
- `InsertLeave` と `FocusLost` で自動保存する設定入り
- 日本語入力のIME切り替え（im-select）にも対応

### tmux

- Prefix は `Ctrl+Q`
- Vim風のペイン操作（`h/j/k/l` で移動、`H/J/K/L` でリサイズ）
- `|` で横分割、`-` で縦分割

### Claude Code

- **コーディングルール**: 全言語共通のルールとDDDのルールをMarkdownで定義して、Claude Codeに読ませている
- **スキル**: 実装プラン作成（`/impl-plan`）、実装開始（`/impl-start`）、PR作成（`/pr-create`）など
- **AIレビューエージェント**: アーキテクト、コードレビュアー、PM、QAの4つの視点でレビューできる

### その他

- `make vscode-key-sync` でVSCodeのキーバインド設定をこのリポジトリに同期＆コミットできる
- フォントは JetBrains Mono Nerd Font を使ってる
