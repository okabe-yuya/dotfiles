---
name: cherry-pick-hotfix
description: |
  PRのURLを指定して、マージコミットをcherry-pickしてhotfixブランチを作成し、PRを作成する。
  「/cherry-pick-hotfix」「hotfix PR作りたい」「cherry-pickしてhotfix」などの要求時に使用。
argument-hint: "<PR URL>"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
---

# cherry-pick-hotfix スキル

マージ済みPRのマージコミットを master ブランチ上に cherry-pick し、hotfix PRを作成する。

## 引数

- `<PR URL>`: GitHub PR の URL（必須）

---

## 実行フロー

### Step 1: 引数の検証

- PR URL が指定されていない場合は「PR URLを指定してください」と報告して**終了する**
- URL から owner/repo と PR 番号を抽出する

### Step 2: PR 情報の取得

以下を `gh` CLI で取得する:

```bash
gh pr view <PR URL> --json mergeCommit,headRefName,state,title
```

中断条件:
- PR がマージされていない場合: 「この PR はまだマージされていません」と報告して終了
- マージコミットが取得できない場合: 「マージコミットが見つかりません」と報告して終了

取得した情報を変数として保持する:
- MERGE_COMMIT: マージコミットの SHA
- SOURCE_BRANCH: 元の PR のブランチ名（headRefName）
- PR_TITLE: 元の PR のタイトル

### Step 3: 作業前の状態確認

以下を並列で実行する:

- `git status --porcelain` で未コミットの変更がないか確認
- `git branch --show-current` で現在のブランチ名を取得

中断条件:
- 未コミットの変更がある場合:
「未コミットの変更があります。先にコミットまたはスタッシュしてください」と報告して終了

### Step 4: master を最新化

```bash
git fetch origin master
git checkout master
git pull origin master
```

失敗時: エラー内容を報告して終了する。

### Step 5: hotfix ブランチの作成と cherry-pick

1. ブランチ名を `hotfix/<SOURCE_BRANCH>` として作成する:

```bash
git checkout -b hotfix/<SOURCE_BRANCH>
```

2. マージコミットを cherry-pick する:

```bash
git cherry-pick -m 1 <MERGE_COMMIT>
```

- `-m 1` はマージコミットの第一親（マージ先）を指定する
- コンフリクトが発生した場合:
コンフリクトの内容を報告し、「コンフリクトを解消してから再度実行してください」と報告して終了する

### Step 6: 差分の確認

cherry-pick 後、master との差分を確認する:

```bash
git diff master...HEAD --stat
git diff master...HEAD
```

中断条件:
- 差分がない場合: 「cherry-pick 後にファイル差分がありません。既に適用済みの可能性があります」と報告して終了する

差分の内容をユーザーに報告し、問題がないか確認する。

### Step 7: push と PR 作成

1. リモートに push する:

```bash
git push -u origin hotfix/<SOURCE_BRANCH>
```

2. PR を作成する:

```bash
gh pr create --base master --title "<PR_TITLE>" --body "$(cat <<'EOF'
## Why / 背景

cherry-pick of <PR URL>

## What / 変更内容

<元PRのdescriptionから要点を1〜2行で簡潔に記載>
EOF
)"
```

- PR body はリポジトリ既存のテンプレート（Why / 背景 + What / 変更内容）に従う
- 内容は簡潔にする。ファイル単位の差分一覧などは書かない

### Step 8: 結果報告

完了後、以下を報告する:

```
✅ hotfix PR を作成しました:

  元 PR: <PR URL>
  マージコミット: <MERGE_COMMIT>
  ブランチ: hotfix/<SOURCE_BRANCH>
  PR URL: <作成した PR の URL>
```

作成した PR をブラウザで開く:

```bash
open <PR URL>
```

---

## 注意事項

- master ブランチ名: リポジトリによっては main の場合がある。`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` でデフォルトブランチ名を取得し、それを使用する
- `--force` は使わない: 強制 push は絶対に行わない
- `--no-verify` は使わない: pre-commit hook が失敗した場合は原因を調査して修正する
- cherry-pick 前に元のブランチに戻す必要がある場合に備えて、Step 3 で取得した元ブランチ名を記憶しておく
