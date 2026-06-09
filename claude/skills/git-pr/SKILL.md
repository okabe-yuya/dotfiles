---
name: git-pr
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

1. ベースブランチを決定する:
   - **引数で指定がある場合**: その値を使用する
   - **引数が未指定の場合**: 現在のブランチの「切り出し元」を推定する。以下を順に試す:
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
   - **推定したベースブランチをユーザーに提示して確認を得る** (例: 「ベースブランチを `feature/parent` と推定しました。これで PR を作成してよいですか？ 違う場合はブランチ名を教えてください」)。ユーザーが別のブランチを指示した場合はそれを採用する
   - 確認なしには push / PR 作成に進まない
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
## Why / 背景
- なぜこの変更が必要なのかを1〜2行で簡潔に記載

## What / 変更内容
- 具体的に何をどう変えたかを1〜3行で簡潔に記載
```

- 本文は簡潔さを最優先する。冗長な説明やファイル単位の差分一覧は書かない
- レビュアーが「なぜ・何を」だけで変更の意図を把握できることを目指す

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

1. `gh pr create` の出力からPRのURLを取得する
2. 以下のコマンドでPRをブラウザで開く:

```bash
open <PR URL>
```

3. 作成したPRのURLを報告する

## 注意事項

- `git push` と `gh pr create` はユーザーの確認なしに実行して良い（このスキルの呼び出し自体がユーザーの意図を表している）
- **ただしベースブランチを自動推定した場合は、push / PR 作成前に必ずユーザーに確認する**（誤った base への PR は影響が大きいため）
- PRの本文は日本語で記載する。ただしリポジトリの既存PRが英語の場合は英語に合わせる
- ドラフトPRにはしない。ドラフトにしたい場合はユーザーが引数で指定する想定

## 引数

ベースブランチ: $ARGUMENTS
