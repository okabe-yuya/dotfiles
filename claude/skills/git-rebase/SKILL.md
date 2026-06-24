---
name: git-rebase
description: |
  指定したブランチをリモートから fetch して最新化し、現在のブランチに rebase で取り込む。
  「/git-rebase」「mainを取り込んで」「rebaseして最新化」などの要求時に使用。
argument-hint: "[target-branch (optional, default: 現在のブランチの切り出し元)]"
user-invocable: true
allowed-tools: Bash
---

# git-rebase スキル

指定したブランチをリモートから fetch して最新にし、現在のブランチに rebase して取り込む。

## 引数

- `[target-branch]` (省略可): 取り込み元のブランチ名。省略時は現在のブランチの「切り出し元」を推定して使用する。

---

## 実行フロー

### Step 1: 状態の確認

以下を並列で実行する:

- `git rev-parse --is-inside-work-tree` で git リポジトリ確認
- `git branch --show-current` で現在のブランチを取得
- `git status --porcelain` で未コミット変更の有無を確認
- `git remote` でリモートが存在するか確認

**中断条件:**
- git リポジトリ外: 「git リポジトリ内で実行してください」と報告して終了
- 現在のブランチが detached HEAD（空文字）: 「detached HEAD 状態では rebase できません」と報告して終了

### Step 2: ターゲットブランチの決定

1. **引数が指定されている場合**: その値を使用する
2. **引数が未指定の場合**: 現在のブランチの「切り出し元」を推定する。以下を順に試す:
   1. `gh pr view --json baseRefName -q .baseRefName 2>/dev/null` で既存 PR の base を取得（存在する場合）
   2. ローカルブランチ一覧から merge-base が最も近いブランチを検出:
      ```bash
      current=$(git branch --show-current)
      git for-each-ref --format='%(refname:short)' refs/heads/ \
        | grep -v "^${current}$" \
        | while read b; do
            mb=$(git merge-base "$b" HEAD 2>/dev/null) || continue
            behind=$(git rev-list --count "${mb}..${b}")
            ahead=$(git rev-list --count "${mb}..HEAD")
            echo "${behind} ${ahead} ${b}"
          done \
        | sort -n -k1,1 -k2,2 \
        | head -1 \
        | awk '{print $3}'
      ```
   3. いずれも取得できない場合はリポジトリのデフォルトブランチ（`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`）にフォールバックする
3. **推定したターゲットブランチをユーザーに提示して確認を得る** (例: 「取り込み元を `feature/parent` と推定しました。これで rebase してよいですか？ 違う場合はブランチ名を教えてください」)。ユーザーが別のブランチを指示した場合はそれを採用する
   - 引数で明示指定された場合は確認不要

**中断条件:**
- 現在のブランチがターゲットブランチと同一の場合: 「現在のブランチがターゲットと同じです。別のブランチに切り替えてから実行してください」と報告して終了

### Step 3: ターゲットブランチを fetch

リモート名は `origin` を前提とする（必要なら `git remote` の出力から判断する）。

```bash
git fetch origin <target-branch>
```

**失敗時:**
- リモートにブランチが存在しない場合: 「`origin/<target-branch>` が見つかりません」と報告して終了
- ネットワークエラー等: エラー内容をそのまま報告して終了

### Step 4: rebase の実行

未コミット変更がある場合は `--autostash` で自動退避する。

```bash
git rebase --autostash origin/<target-branch>
```

**コンフリクト発生時:**
- 「コンフリクトが発生しました。以下のいずれかを実行してください:」と報告して終了
  - 解消してから `git rebase --continue`
  - 中断したい場合は `git rebase --abort`
- スキル側で自動的に `--abort` はしない（ユーザーの作業を失わないため）

**autostash が失敗した場合（stash pop 時のコンフリクト等）:**
- 状況をそのまま報告して終了。ユーザーに stash の解消を任せる

### Step 5: 結果報告

成功時、以下を報告する:

```
✅ origin/<target-branch> を取り込みました

  取り込み元: origin/<target-branch> ({short-sha})
  現在のブランチ: <current-branch>
  取り込んだコミット数: {N}
```

取り込んだコミット数は `git rev-list --count ORIG_HEAD..HEAD` で取得する（rebase 直後は `ORIG_HEAD` が rebase 前の HEAD を指す）。

取り込むコミットがなかった場合（既に最新）は以下を報告する:

```
✅ 既に origin/<target-branch> の最新を取り込み済みです
```

---

## 注意事項

- **`--force` push は行わない**: rebase 後にリモートへ反映する判断はユーザーに委ねる。push が必要な場合はユーザーが明示的に依頼するか、`/git-cp` 等の別スキルで行う
- **`--no-verify` は使わない**: rebase 中の hook が失敗した場合は原因を調査する
- **merge は使わず rebase のみ**: 履歴を直線的に保つ
- **fetch するのはターゲットブランチのみ**: `git fetch --all` ではなく必要なブランチに限定する
