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
- `git rev-parse --abbrev-ref @{upstream} 2>/dev/null` で upstream の有無を確認

**中断条件:**
- git リポジトリ外: 「git リポジトリ内で実行してください」と報告して終了
- 変更なし: 「コミット対象の変更がありません」と報告して終了
- `main` / `master` ブランチ: 「main / master 上では実行できません。feature ブランチに切り替えてください」と報告して終了

### Step 2: 変更内容の把握

並列で以下を実行:

- `git diff` で modified ファイルの差分取得
- `git diff --cached` でステージ済み変更があれば取得
- untracked ファイルは `Read` で内容を確認（小さいファイルのみ。大きすぎる場合は `wc -l` 等で概要把握）

### Step 2.5: 未 push コミットの把握（fixup 候補の特定）

集約候補となる「未 push かつ未 push 範囲のローカルコミット」を取得する:

- upstream が設定されている場合: `git log @{upstream}..HEAD --oneline` で未 push コミット一覧を取得
- upstream 未設定の場合: ベースブランチ（`origin/main` / `origin/master` 等）を推定し、`git log <base>..HEAD --oneline` で取得

**重要:** 既に push 済みのコミットは fixup 対象にしない。fixup 後の autosquash は履歴を書き換えるため、push 済みコミットに対して行うと force push が必要になり破壊的になる。

未 push コミットが存在する場合、各コミットの diff（`git show <sha>`）を確認し、今回の変更との関連性を判定する。

### Step 3: 論理単位の判定（新規コミット vs fixup）

変更を以下の観点でグルーピングする:

**既存の未 push コミットに集約できるか積極的に検討する:**
- 直前のコミットで追加したコードのタイポ修正 / 軽微なバグ修正 → fixup
- 直前のコミットで追加した機能の補足（テスト追加・lint 修正・コメント追加等） → fixup
- 既存コミットの意図と「同じ意図で読める」変更 → fixup
- 新しい論理単位（別機能・独立した修正） → 新規コミット

**新規コミットのグルーピング基準:**
- **同じ機能領域**: 関連する設定・実装・テストは1コミットにまとめる（例: `cage/presets.yml` + `Makefile`の cage ターゲット + `zshrc`の cage 用 export）
- **テストとプロダクションコード**: 同じ機能の追加なら同じコミット
- **独立した別機能**: 別コミット
- **無関係なフォーマット変更**: 別コミットに切り出す

**粒度の判断基準:**
- 1コミットあたり、レビュー時に「同じ意図で読める」範囲に収める
- 1ファイルが複数の論理変更を含む場合は `git add -p` での分割も検討する
- 迷ったら fixup を優先する。push 前であれば autosquash で履歴は綺麗に保てる

### Step 4: コミット計画の提示

決定したグルーピングを簡潔に報告する。fixup 対象は元コミットの sha と subject を明示する:

```
以下の計画で実行します:

[fixup]
1. <sha> "feat: cageの導入" に fixup — cage/presets.yml の typo 修正
2. <sha> "feat: workspaceスクリプトを追加" に fixup — workspace/run.sh の権限修正

[新規コミット]
3. feat: claude設定でgit commit/pushをブロック — claude/settings.json

fixup 適用後、autosquash で元コミットに統合します。
```

ユーザーから明示的な却下がない限り、続けて実行する（過度な確認はしない）。

### Step 5: コミット実行

**新規コミット:**

各論理単位ごとに、以下を逐次実行:

```bash
git add <files>
git commit -m "<message>"
```

**fixup コミット:**

対象の元コミット sha を指定して fixup コミットを作成:

```bash
git add <files>
git commit --fixup=<sha>
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

### Step 5.5: autosquash で fixup を統合

fixup コミットを作成した場合のみ実行する。新規コミットのみの場合はスキップする。

統合のベース ref は「最も古い fixup 対象コミットの1つ前」を指定する:

```bash
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <oldest-fixup-target>^
```

`GIT_SEQUENCE_EDITOR=:` で対話エディタを抑止して非対話的に実行する。

**rebase 失敗時:**
- コンフリクト等で停止した場合は `git rebase --abort` で安全に戻し、ユーザーに状況を報告して中断する
- `--force` push が必要になるような状態にはしない

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
- **fixup の対象は未 push コミットのみ**: push 済みコミットへの fixup + autosquash は force push が必要になるため絶対に行わない
