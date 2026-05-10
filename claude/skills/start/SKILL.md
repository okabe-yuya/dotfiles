---
name: start
description: |
  指定したベースブランチを最新化して新規ブランチを作成し、プランモードに入って
  Notion / Linear などのドキュメントURLや既存コードベースを参照しながら実装計画を作成する。
  プランがユーザーに承認されたら、引き続き実装を開始する。
  「/start」「機能開発を始める」「タスクに着手する」などの要求時に使用。
argument-hint: "<base-branch>"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, EnterPlanMode, ExitPlanMode, AskUserQuestion, ToolSearch, WebFetch, TaskCreate, TaskUpdate
---

# /start スキル

ベースブランチからの新規ブランチ作成 → プラン作成 → 実装開始までを一気通貫で行うスキル。

## 引数

- `<base-branch>`: 派生元のブランチ（例: `main`, `develop`）。**必須**。

引数が未指定の場合は、ベースブランチが不明である旨を報告して**終了する**。

---

## 実行フロー

### Step 1: 前提条件の確認

以下を並列で実行して環境を把握する:

- `git rev-parse --is-inside-work-tree` で git リポジトリ内であることを確認
- `git status --porcelain` で未コミットの変更がないか確認
- `git rev-parse --verify <base-branch>` および `git rev-parse --verify origin/<base-branch>` でベースブランチの存在確認
- `pwd` で現在の作業ディレクトリを取得

**中断条件:**
- git リポジトリ外: 「git リポジトリ内で実行してください」と報告して終了
- 未コミット変更あり: 変更内容を一覧表示して「先に commit / stash してください」と報告して終了
- ベースブランチが存在しない: 報告して終了

### Step 2: `.claude-doc` の global ignore 設定

プランファイル出力先 `.claude-doc/` を git の global ignore に追加する。

```bash
# 現在の設定を確認
git config --global --get core.excludesFile
```

**core.excludesFile が未設定の場合:**

```bash
mkdir -p ~/.config/git
touch ~/.config/git/ignore
git config --global core.excludesFile ~/.config/git/ignore
```

**`.claude-doc` がまだ ignore リストにない場合:**

```bash
# 重複追加を避けるため grep で確認してから append する
grep -qxF '.claude-doc/' "$(git config --global --get core.excludesFile)" \
  || echo '.claude-doc/' >> "$(git config --global --get core.excludesFile)"
```

ignore 設定の追加内容をユーザーに報告する。

### Step 3: ベースブランチを最新化

```bash
git fetch origin <base-branch>
```

ローカルの `<base-branch>` が origin/<base-branch> より遅れている場合は、現在のブランチがどこかを確認した上で:

- 現在のブランチが `<base-branch>` と同じ: `git merge --ff-only origin/<base-branch>` で fast-forward
- 別ブランチにいる: `git fetch` だけ済ませて、Step 4 で origin/<base-branch> を起点に新規ブランチを切る（local <base-branch> は触らない）

**fast-forward できない場合:**
- ローカルとリモートが分岐している旨を報告して終了。先に手動で解消してもらう。

### Step 4: 新規ブランチ名の確認と作成

新しいブランチ名をユーザーに確認する。AskUserQuestion ではなく、ターミナルでの対話を想定して、以下のように案内し回答を求める:

```
新規ブランチ名を入力してください（例: feat/xxx-yyy）:
```

ユーザーから受け取ったブランチ名を:

- `feat/`, `fix/`, `chore/`, `docs/`, `refactor/` 等のプレフィックスを推奨
- 既に同名ブランチが存在しないことを確認 (`git rev-parse --verify <new-branch>`)

問題なければ origin/<base-branch> から新規ブランチを切る:

```bash
git checkout -b <new-branch> origin/<base-branch>
```

### Step 5: プランモードへ移行

`EnterPlanMode` ツールを呼び出してプランモードに切り替える。

以降、Step 6〜9 はプランモード中に実行する。**ファイル変更系のツール（Edit/Write）はプランモード中に使えない**ため、調査と計画作成（Write は最終ステップで例外的に許可される設計）に集中する。

> **注:** プランモードではファイル変更がブロックされるため、プランファイル自体の書き込みは ExitPlanMode 後に行う。Step 8 でプランの中身は内部的に組み立てておき、Step 10 でファイルとして書き出す。

### Step 6: 実装情報の収集

ユーザーに「実装したい内容のドキュメント URL またはタスク説明」を求める。

```
実装する機能の情報を教えてください:
  - Notion の URL
  - Linear の URL
  - その他 URL（GitHub Issue、社内 Wiki など）
  - またはタスク内容を直接記述
```

入力に応じて以下を実行:

#### Notion URL の場合 (`https://notion.so/` または `https://www.notion.so/`)

```
ToolSearch で "select:mcp__claude_ai_notion__notion-fetch" を実行してツールをロード
↓
mcp__claude_ai_notion__notion-fetch でページ内容を取得
```

取得失敗時は理由を報告し、ユーザーに直接タスク内容を貼ってもらう。

#### Linear URL の場合 (`https://linear.app/`)

Linear 公式の MCP ツールがあれば優先する。なければ `WebFetch` で取得を試み、ログインが必要で取得できない場合はユーザーにチケット内容を貼ってもらう。

#### その他 URL の場合

`WebFetch` で内容を取得。失敗したらユーザーに内容を求める。

#### URL なし (テキスト入力) の場合

そのままタスク説明として扱う。

### Step 7: コードベース調査

タスクに関連するコードベースを調査する:

- 関連ファイルの特定（Glob, Grep）
- 既存の実装パターンの確認（Read）
- 影響範囲の把握（依存・呼び出し関係）

調査範囲が広い場合は `general-purpose` または `Explore` エージェントへ委譲してもよい。

### Step 8: プラン本体の組み立て

以下のセクションを含むプランを組み立てる。

```markdown
# {タスクタイトル}

- ステータス: Draft
- ブランチ: {new-branch}
- ベース: {base-branch}
- 起票元: {URL or テキスト}
- 作成日時: YYYY-MM-DD HH:MM:SS

## 背景
（なぜこの実装が必要か。元ドキュメントから抜粋・要約）

## ゴール
- 達成すべきこと
- 達成しないこと（スコープ外）

## 影響範囲
### 変更対象ファイル
- path/to/file1
- path/to/file2

### 影響を受ける機能
- ...

## 実装ステップ

### Phase 1: {小見出し}
- [ ] ステップ1
- [ ] ステップ2

### Phase 2: {小見出し}
- [ ] ...

## テスト方針
- 正常系・異常系・境界値で必要なテストケース

## 確認事項
- [ ] ユーザーに確認したい技術判断（必要に応じて）
```

### Step 9: 実装イメージの確認 (ExitPlanMode)

組み立てたプランの **要約** を `ExitPlanMode` ツールに渡してユーザーに提示する。要約は以下のフォーマット:

```markdown
## 実装方針

### ゴール
- ...

### 主な変更
- {ファイル/モジュール}: {何をするか}

### Phase 構成
- Phase 1: ...
- Phase 2: ...

### 確認事項
- ...
```

ExitPlanMode の結果でユーザーが:

- **承認**: Step 10 へ進む
- **却下/修正要求**: 指摘内容を反映するため、Step 6 または Step 8 に戻る

### Step 10: プランファイルの書き出し

プラン承認後、以下のパスにプランファイルを出力する。

**出力先:** `<cwd>/.claude-doc/`
**ファイル名:** `YYYYMMDD-HHMMSS-{branch-slug}.md`
（branch-slug は `<new-branch>` の `feat/` などのプレフィックスを除いた部分）

```bash
mkdir -p .claude-doc
date "+%Y%m%d-%H%M%S"
```

ファイルパスをユーザーに報告する。

### Step 11: 実装の開始

プランファイルが出力できたら、引き続き実装を進める。

#### 11.1 Phase 選択

プランの「実装ステップ」セクションから Phase 一覧を抽出して提示し、開始 Phase を確認する（通常は Phase 1）:

```
プラン: {タスクタイトル}

Phase 1: {小見出し}  [未着手]
Phase 2: {小見出し}  [未着手]
...

どの Phase から実装を開始しますか？
```

#### 11.2 タスク登録と実装

選択された Phase のステップを `TaskCreate` で登録し、`in_progress` → `completed` で逐次進める。

実装時のルール:
- プロジェクトの `coding-general.md` / `coding-ddd.md` のルールを遵守する
- 影響範囲セクションに記載されたファイルを優先的に確認・編集する
- Phase 内の独立したステップは並行して実行する
- 大きな設計判断が必要な場合は `architect` エージェントへ委譲する

#### 11.3 Phase 完了時のレビュー

Phase 内の全ステップが完了したら、以下の2つのエージェントを **同時にバックグラウンドで起動** する:

- **code-reviewer**: コード品質、コーディングルール準拠、セキュリティ・パフォーマンス
- **qa-reviewer**: テスト網羅性（正常系・異常系・境界値）、テスト品質

両エージェントの結果を統合してユーザーに報告し、CRITICAL / HIGH の指摘があれば修正する。修正後、プランファイル内の Phase に完了マーク（例: `### Phase 1: 認証基盤 [完了]`）を付ける。

#### 11.4 次の Phase へ

未完の Phase があれば、続行するか確認する。すべて完了したらプランファイルのステータスを `Completed` に更新し、`/git-pr` での PR 作成を提案する。

---

## 中断・再開

途中で中断した場合は、既存のプランファイルパスを指定して再開できる。プランファイルにはステータスと Phase ごとの完了状況が記録されているため、続きから進められる。

```
このプランの Phase 2 から再開してください: .claude-doc/20260510-180000-foo.md
```

のように Claude に直接指示すれば良い。

---

## 注意事項

- **未コミット変更がある状態では実行しない**: ブランチ切替時に変更が紛れ込むのを防ぐ
- **ブランチ名はユーザーから必ず確認する**: 自動生成しない
- **プランモード中はファイル書き出しをしない**: Write は ExitPlanMode 後の Step 10 で行う
- **`.claude-doc/` はリポジトリにコミットしない**: global ignore 設定により自動的に追跡対象外
