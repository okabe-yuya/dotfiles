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

### 3. kotlin-lsp（Kotlin の LSP）

```sh
make kotlin-lsp   # 最新ビルドを ~/.local/bin/kotlin-lsp に用意 (約360MB DL)
```

nvim 側（`nvim/lua/plugins/lsp.lua`）は `kotlin_lsp` を enable 済みで、PATH 上の
`kotlin-lsp` を `--stdio` で起動する。JetBrains 公式の kotlin-lsp は pre-alpha で
**ビルドが約30日で失効する**（起動時に `This build of intellij-server has expired.`）ため
brew では管理せず、`scripts/kotlin-lsp-update.sh` で JetBrains CDN から最新版へ貼り替える
（`~/.local/share/kotlin-lsp/<version>/` に展開し `~/.local/bin/kotlin-lsp` へ symlink）。
失効したら `make kotlin-lsp` を再実行するだけでよい。

前提・注意:
- **`~/.local/bin` が PATH（できれば homebrew より前）にあること**。スクリプト末尾で
  実際に解決される `kotlin-lsp` がこの symlink かを検証し、ずれていれば警告する。
- brew 版から移行する場合は残存を削除する: `brew uninstall kotlin-lsp && brew untap jetbrains/utils`
  （`brew bundle` は Brewfile から行を消しても既存 formula を uninstall しないため手動で行う）。
- `make kotlin-lsp` が「既に最新」で終わるのに失効する場合は、JetBrains 側の新リリース待ち
  （リリース間隔が失効期間を超えたケース）。新バージョンが出れば再実行で解消する。

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
