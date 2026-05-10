---
name: git-cp
description: |
  未コミットの変更を論理単位に分けて複数コミットに分割し、リモートへ push する。
  「/git-cp」「commit & push」「コミットしてプッシュ」などの要求時に使用。
argument-hint: "[remote (optional, default: origin)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---

# git-cp スキル

未コミットの変更を分析し、適切な粒度の論理単位に分けてコミット → push を行う。

## 引数

- `[remote]` (省略可): push 先のリモート名。省略時は `origin`。

---

## 実行フロー

### Step 1: 状態の確認

以下を並列で実行する:

- `git rev-parse --is-inside-work-tree` で git リポジトリ確認
- `git status --porcelain` で変更状況取得
- `git branch --show-current` で現在のブランチ取得
- `git log --oneline -5` でコミットメッセージのスタイル確認

**中断条件:**
- git リポジトリ外: 「git リポジトリ内で実行してください」と報告して終了
- 変更なし: 「コミット対象の変更がありません」と報告して終了
- `main` / `master` ブランチ: 「main / master 上では実行できません。feature ブランチに切り替えてください」と報告して終了

### Step 2: 変更内容の把握

並列で以下を実行:

- `git diff` で modified ファイルの差分取得
- `git diff --cached` でステージ済み変更があれば取得
- untracked ファイルは `Read` で内容を確認（小さいファイルのみ。大きすぎる場合は `wc -l` 等で概要把握）

### Step 3: 論理単位の判定

変更を以下の観点でグルーピングする:

- **同じ機能領域**: 関連する設定・実装・テストは1コミットにまとめる（例: `cage/presets.yml` + `Makefile`の cage ターゲット + `zshrc`の cage 用 export）
- **テストとプロダクションコード**: 同じ機能の追加なら同じコミット
- **独立した別機能**: 別コミット
- **無関係なフォーマット変更**: 別コミットに切り出す

**粒度の判断基準:**
- 1コミットあたり、レビュー時に「同じ意図で読める」範囲に収める
- 1ファイルが複数の論理変更を含む場合は `git add -p` での分割も検討する

### Step 4: コミット計画の提示

決定したグルーピングを簡潔に報告する:

```
以下の {N} コミットに分割します:

1. feat: cageの導入 — cage/presets.yml, Makefile, zsh/.zshrc
2. feat: claude設定でgit commit/pushをブロック — claude/settings.json
3. feat: workspaceスクリプトを追加 — scripts/workspace/
```

ユーザーから明示的な却下がない限り、続けて実行する（過度な確認はしない）。

### Step 5: コミット実行

各論理単位ごとに、以下を逐次実行:

```bash
git add <files>
git commit -m "<message>"
```

**コミットメッセージのルール:**
- 直近の `git log --oneline -5` のスタイルに合わせる
- 既存のスタイルが不明な場合は `<type>: <日本語の短い説明>` を使用
  - `type` の選択: `feat` / `fix` / `refactor` / `docs` / `chore` / `test` / `style`
- HEREDOC を使う必要があれば `git commit -m "$(cat <<'EOF' ... EOF)"` 形式を使う
- **Co-Authored-By トレーラーは付けない** （リポジトリのスタイルに合わせる場合は除く）

**注意:**
- `git add -A` や `git add .` は使わない。意図しないファイル（`.env`, `node_modules`, シークレット等）が混入するリスクがあるため、**ファイル名を明示的に指定**する
- `.env`, `credentials.json` 等のシークレット候補ファイルは検知してユーザーに警告し、合意なしには含めない

### Step 6: push

- `git rev-parse --abbrev-ref @{upstream}` で upstream 設定の有無を確認

**upstream が未設定の場合:**

```bash
git push -u <remote> <current-branch>
```

**upstream 設定済みの場合:**

```bash
git push <remote> <current-branch>
```

**push 失敗時 (non-fast-forward):**
- リモートが進んでいる旨を報告し、`git pull --rebase` で先に同期するか確認する
- 強制 push は **絶対に自動実行しない**

### Step 7: 結果報告

完了後、以下を報告する:

```
✅ {N} コミットを作成して push しました:

  {commit-sha} {commit-message-1}
  {commit-sha} {commit-message-2}
  ...

リモート: {remote}/{branch}
```

---

## permissions との関係

`~/.claude/settings.json` の `permissions.ask` に `Bash(git commit:*)` / `Bash(git push:*)` が登録されている場合、各コマンド実行時に毎回ユーザーへの許可プロンプトが出る。プロンプトでユーザーが拒否した場合は、その旨を報告して以降の処理を中断する。

`permissions.deny` に登録されている場合は実行不可（プロンプトすら出ない）。その場合はユーザーに deny → ask への変更を提案して終了する。

---

## 注意事項

- **既にステージされた変更がある場合**: そのステージ済み変更を最初のコミットに含めるか、ユーザーに確認する
- **巨大な変更 (10ファイル超)**: グルーピング判断が難しいため、ユーザーに方針を確認してから進める
- **`main` / `master` ブランチでは実行しない**: 直接コミット・push されると影響が大きいため
- **`--no-verify` は使わない**: pre-commit hook が失敗した場合は、原因を調査して修正する
- **`--amend` / `--force` は使わない**: 既存コミットを破壊しない
