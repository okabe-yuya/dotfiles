---
name: pr-create
description: 現在のブランチからGitHub PRを作成し、ブラウザで開く
argument-hint: "<ベースブランチ>"
allowed-tools: Bash, Read, Grep, Glob
---

# PR 作成スキル

現在のブランチの変更内容を分析し、GitHub上にPRを作成してブラウザで開く。

## 実行手順

### Step 1: 状態の確認

1. 以下のコマンドを並列で実行して現在の状態を把握する:
   - `git status` で未コミットの変更がないか確認
   - `git branch --show-current` で現在のブランチ名を取得
   - `git remote -v` でリモートの設定を確認
2. 未コミットの変更がある場合は、コミットされていない変更がある旨を報告して**終了する**
3. 現在のブランチが `main` の場合は、mainブランチ上ではPRを作成できない旨を報告して**終了する**

### Step 2: ベースブランチの決定とdiff取得

1. 引数で指定されたベースブランチを使用する。**引数が未指定の場合はベースブランチが不明である旨を報告して終了する**
2. 以下のコマンドを実行して変更内容を把握する:
   - `git log <base-branch>...HEAD --oneline` でコミット一覧を取得
   - `git diff <base-branch>...HEAD --stat` で変更ファイルの統計を取得
   - `git diff <base-branch>...HEAD` で全体の差分を取得
3. 差分がない場合は報告して**終了する**

### Step 3: PRテンプレートの確認

1. 以下のパスにPRテンプレートが存在するか確認する:
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `docs/pull_request_template.md`
   - `pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE/` ディレクトリ配下
2. テンプレートが見つかった場合は読み込み、Step 5でその形式に従う

### Step 4: 変更内容の分析

1. コミット一覧とdiffの内容から以下を把握する:
   - 変更の目的・背景（なぜこの変更が必要か）
   - 具体的な変更箇所（何をどう変えたか）
2. 変更されたファイルの中で重要なものは内容を読み込み、変更の意図を正確に把握する

### Step 5: PRの作成

1. **タイトル**: 変更内容を簡潔に表す（70文字以内）
   - 形式: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:` 等のprefixを付ける
   - コミットメッセージの傾向がある場合はそれに合わせる

2. **本文**: テンプレートが存在する場合はその形式に従う。テンプレートがない場合は以下の形式を使う:

```markdown
## 背景
- なぜこの変更が必要なのかを箇条書きで記載

## 変更箇所
- 具体的に何をどう変えたかを箇条書きで記載
```

3. 以下のコマンドでリモートにpushしてPRを作成する:

```bash
git push -u origin <current-branch>
```

```bash
gh pr create --base <base-branch> --title "<タイトル>" --body "$(cat <<'EOF'
<本文>
EOF
)"
```

4. PRの作成に失敗した場合はエラー内容を報告して**終了する**

### Step 6: ブラウザで開く

1. PRが正常に作成されたら、以下のコマンドでブラウザで開く:

```bash
gh browse
```

2. 作成したPRのURLを報告する

## 注意事項

- `git push` と `gh pr create` はユーザーの確認なしに実行して良い（このスキルの呼び出し自体がユーザーの意図を表している）
- PRの本文は日本語で記載する。ただしリポジトリの既存PRが英語の場合は英語に合わせる
- ドラフトPRにはしない。ドラフトにしたい場合はユーザーが引数で指定する想定

## 引数

ベースブランチ: $ARGUMENTS
