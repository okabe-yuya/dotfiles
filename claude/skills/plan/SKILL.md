---
name: plan
description: |
  指定したベースブランチを最新化して新規ブランチを作成し、Notion / Linear などのドキュメント
  URLや既存コードベースを参照しながら実装計画を HTML として作成・ブラウザで開く。
  ユーザーから承認があれば bypass permission モードのまま実装に進む。
  「/plan」「プランを作って」「実装計画を立てて」などの要求時に使用。
argument-hint: "<base-branch>"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, WebFetch, TaskCreate, TaskUpdate
---

# /plan スキル

ベースブランチからの新規ブランチ作成 → HTML プラン作成・ブラウザ表示 → ユーザー承認 → 実装開始までを一気通貫で行うスキル。

**重要:** このスキルは cage + `--dangerously-skip-permissions`（bypass permission）モードでの利用を前提としている。`EnterPlanMode` は使わず、プランは HTML ファイルとして `<workspace_root>/.claude-doc/<repo_name>/` に書き出してブラウザで開き、ユーザーからの承認後はそのまま bypass permission モードで実装を続ける。

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

### Step 2: プラン出力先ディレクトリの準備

プランファイルは各リポジトリの `<cwd>/.claude-doc/` ではなく、**リポジトリの1つ上の階層（ワークスペースルート）に集約**する（複数リポジトリ（henry-backend, henry-web 等）を横断して作業する際に `.claude-doc/` があちこちに散らばるのを防ぐため）。

```bash
# 現在の git リポジトリのルート名をサブディレクトリ名として使う
repo_toplevel="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$repo_toplevel")"
workspace_root="$(dirname "$repo_toplevel")"
mkdir -p "$workspace_root/.claude-doc/$repo_name"
```

**注意:** ホームディレクトリ直下（`~/.claude-doc/` 等）への書き込みはサンドボックス環境で権限エラーになることがある（実績あり）。ワークスペースルート（プロジェクトツリー内）への書き込みに留める。

出力先 `$workspace_root/.claude-doc/<repo_name>/` は、ワークスペースルート自体が git リポジトリの場合はその working tree に含まれる。global の `core.excludesFile` に `.claude-doc/` パターンが登録済みかを確認し、無ければ追加する（末尾スラッシュなしパターンは全階層にマッチする）:

```bash
git config --global --get core.excludesFile
# 未設定なら
mkdir -p ~/.config/git && touch ~/.config/git/ignore && git config --global core.excludesFile ~/.config/git/ignore
# .claude-doc/ が未登録なら追加
grep -qxF '.claude-doc/' "$(git config --global --get core.excludesFile)" \
  || echo '.claude-doc/' >> "$(git config --global --get core.excludesFile)"
```

**フォールバック:** `workspace_root` への書き込みが権限エラーになる場合（例: リポジトリが直接ホーム直下やアクセス制限のある場所にある）は、従来通り `<cwd>/.claude-doc/`（リポジトリ自身の直下）にフォールバックする。

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

### Step 5: 実装情報の収集

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

### Step 6: コードベース調査

タスクに関連するコードベースを調査する:

- 関連ファイルの特定（Glob, Grep）
- 既存の実装パターンの確認（Read）
- 影響範囲の把握（依存・呼び出し関係）

調査範囲が広い場合は `general-purpose` または `Explore` エージェントへ委譲してもよい。

### Step 7: プラン本体の組み立て

以下のセクションを含むプランを内部的に組み立てる。情報量が多くなるため、**「概要」と「詳細」の 2 段構成**を前提に組み立てる（Step 8 のテンプレート参照）。概要だけ読めば全体像が把握でき、詳細は折りたたみで必要な箇所だけ確認できるようにする。

**概要に含めるもの**（一覧性・確認しやすさを優先し、簡潔に）:

- **タスクタイトル**
- メタ情報（ステータス: Draft / ブランチ / ベース / 起票元 / 作成日時 YYYY-MM-DD HH:MM:SS）
- **背景**: なぜこの実装が必要か。元ドキュメントから抜粋・要約（数行程度）
- **ゴール**: 達成すべきこと / 達成しないこと（スコープ外）を簡潔に
- **確認事項**: ユーザーに確認したい技術判断（あれば概要に目立つ形で配置する。実装着手のブロッカーになり得るため埋もれさせない）
- **実装ステップ一覧**: Phase タイトルと一言要約のみ（詳細への内部リンク付き）

**詳細（折りたたみ）に含めるもの**:

- **影響範囲**: 変更対象ファイル / 影響を受ける機能
- **技術方針（調査結果）**: 既存アーキテクチャの調査結果、採用する設計判断とその理由
- **実装ステップ**: Phase ごとにチェックリスト形式 + **サンプルコード**
  - 各 Phase、特に既存パターンの転用・新しい型定義・複雑なロジック変更を伴う Phase には、具体的なサンプルコード（対象言語のシンタックスで、実際のファイル名・関数名を示す）を添える。プレーンな箇条書き説明だけで済ませない
  - サンプルコードは「実装イメージ」であることを明記し、実装時に既存コードとの整合を取る前提とする
- **テスト方針**: 正常系・異常系・境界値で必要なテストケース

**コメント欄の使い分け:**
- **確認事項** → セレクトボックス（OK / 修正必要 / 質問あり / その他）。定型回答で素早く確認できる
- **Phase** → テキストエリア直表示（`always-show`）。自由記入のみ
- フィードバック反映後は `.comment-section.resolved` クラスを付けて「解決済み」表示にする

### Step 8: HTML プランの書き出しとブラウザ表示

プランを HTML として `<workspace_root>/.claude-doc/<repo_name>/` 配下に書き出してブラウザで開く（Step 2 参照。リポジトリ自身の `<cwd>/.claude-doc/` には作らない。フォールバック時のみそちらを使う）。

**出力先:** `<workspace_root>/.claude-doc/<repo_name>/`（`workspace_root` = リポジトリの1つ上の階層）
**ファイル名:** `YYYYMMDD-HHMMSS-{branch-slug}.html`
（branch-slug は `<new-branch>` の `feat/` などのプレフィックスを除いた部分）

```bash
# シェル変数は Bash 呼び出しをまたいで残らないため、Step 2 と同じ計算をここでも行う
repo_toplevel="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$repo_toplevel")"
workspace_root="$(dirname "$repo_toplevel")"
echo "$workspace_root/.claude-doc/$repo_name"
date "+%Y%m%d-%H%M%S"
```

**HTML テンプレート（概要 / 詳細の 2 段構成 + サンプルコード + シンタックスハイライト）:**

情報量が多いプランは一覧性が落ちて確認しづらくなる。そのため **概要（常に展開）** と **詳細（`<details>` で折りたたみ）** に分割し、概要だけでも全体像・確認事項が把握できるようにする。詳細セクションの各 Phase には可能な限り具体的な**サンプルコード**（対象言語の実際のファイル名・関数名を使ったイメージコード）を添える。コードブロックには依存なしの簡易シンタックスハイライトを当てる（CDN 不可のオフライン環境のため自前 JS で実装）。

```html
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <title>{タスクタイトル}</title>
  <style>
    /* 常に白基調（ダークモード非対応。system dark mode でも白背景を強制する） */
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif;
      max-width: 920px; margin: 2rem auto; padding: 0 1.5rem 4rem; line-height: 1.75;
      background: #ffffff; color: #1f2328;
    }
    /* 見出し・段落・リスト等、コンポーネントごとに明示的な margin を持たせる（詰まって見えるのを防ぐ） */
    h1 { margin: 0 0 1.5rem; border-bottom: 2px solid #888; padding-bottom: .5rem; }
    h2 { margin: 3rem 0 1.2rem; border-left: 4px solid #4a90e2; padding-left: .6rem; }
    h2:first-of-type { margin-top: 0; }
    h2.section-title { border-left-color: #d9534f; font-size: 1.3em; }
    h3 { margin: 2rem 0 .8rem; }
    h3:first-child { margin-top: 0; }
    h4 { margin: 1.6rem 0 .6rem; }
    h4:first-child { margin-top: 0; }
    p { margin: 0 0 1rem; }
    ul, ol { margin: 0 0 1.2rem; padding-left: 1.5rem; }
    li { margin-bottom: .3rem; }
    .meta { background: #f6f8fa; padding: 1rem 1.2rem; border-radius: 6px; font-size: .9rem; margin-bottom: 2rem; }
    .meta dt { font-weight: 600; float: left; width: 8rem; clear: left; }
    .meta dd { margin-left: 8rem; margin-bottom: .4rem; }
    code { background: #eef0f2; padding: 1px 5px; border-radius: 3px; font-size: .9em; }
    pre { background: #f6f8fa; border: 1px solid #e1e4e8; padding: 1rem 1.2rem; border-radius: 6px;
          overflow-x: auto; font-size: .85em; margin: 0 0 1.2rem; }
    pre code { background: none; padding: 0; }
    .status { display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: .8rem;
              background: #f0ad4e; color: #fff; }
    table { border-collapse: collapse; width: 100%; margin: 0 0 1.2rem; }
    th, td { border: 1px solid #d8dce0; padding: .5rem .7rem; text-align: left; font-size: .9em; }
    th { background: #f6f8fa; }
    .warn { background: #fef6e7; border-left: 4px solid #f0ad4e; padding: .8rem 1.2rem; border-radius: 4px; margin: 0 0 1.2rem; }
    .confirm { background: #fdf1f0; border-left: 4px solid #d9534f; padding: .8rem 1.2rem; border-radius: 4px; margin: 0 0 1rem; }
    .toc { padding-left: 0; list-style: none; margin-bottom: 1.5rem; }
    .toc li { margin-bottom: .5rem; }
    .toc a { text-decoration: none; color: #1d63c9; }
    .toc a:hover { text-decoration: underline; }
    .expand-all { font-size: .85em; background: #fff; border: 1px solid #c8ccd1;
      border-radius: 4px; padding: .4rem .8rem; cursor: pointer; margin: 0 .6rem 1.2rem 0; }
    /* 詳細セクション: 折りたたみ */
    details.phase, details.block {
      background: #f7f9fc; border: 1px solid #e1e6ec; border-radius: 8px; margin: 0 0 1.2rem; padding: 1rem 1.4rem;
    }
    details.phase > summary, details.block > summary {
      cursor: pointer; font-weight: 700; font-size: 1.05em; padding: .3rem 0; list-style: none;
    }
    details.phase[open] > summary, details.block[open] > summary { margin-bottom: 1rem; }
    details.phase > summary::-webkit-details-marker, details.block > summary::-webkit-details-marker { display: none; }
    details.phase > summary::before, details.block > summary::before { content: "▶ "; }
    details.phase[open] > summary::before, details.block[open] > summary::before { content: "▼ "; }
    details.phase > :last-child, details.block > :last-child { margin-bottom: 0; }
    summary .hook { font-weight: 400; color: #6a737d; font-size: .85em; margin-left: .4rem; }
    /* コメント機能 */
    .comment-section {
      margin-top: 1rem; padding-top: .8rem; border-top: 1px dashed #d0d7de;
    }
    .comment-section.resolved {
      opacity: .6; pointer-events: none;
    }
    .comment-section.resolved::before {
      content: "解決済み"; display: inline-block; font-size: .8em; font-weight: 600;
      color: #fff; background: #2da44e; padding: 1px 8px; border-radius: 10px; margin-bottom: .4rem;
    }
    .comment-form { margin-top: .5rem; }
    .comment-form select {
      width: 100%; padding: .4rem .5rem; border: 1px solid #d0d7de;
      border-radius: 6px; font-size: .85em; font-family: inherit;
      background: #fff; color: #1f2328; cursor: pointer;
    }
    .comment-form select:focus { outline: none; border-color: #4a90e2; box-shadow: 0 0 0 2px rgba(74,144,226,.2); }
    .comment-form textarea {
      width: 100%; min-height: 60px; padding: .5rem; border: 1px solid #d0d7de;
      border-radius: 6px; font-size: .85em; font-family: inherit; resize: vertical;
      background: #fff; color: #1f2328; margin-top: .4rem; display: none;
    }
    .comment-form textarea.show { display: block; }
    .comment-form textarea.always-show { display: block; margin-top: 0; }
    .comment-form textarea:focus { outline: none; border-color: #4a90e2; box-shadow: 0 0 0 2px rgba(74,144,226,.2); }
    /* 承認バー（回答出力 + 承認ボタンを統合） */
    .approval-bar {
      position: sticky; bottom: 0; background: #f6f8fa; border-top: 2px solid #d0d7de;
      padding: 1rem 1.5rem; z-index: 10;
    }
    .answer-output {
      margin: 0 0 .8rem; padding: 0;
    }
    .answer-output pre {
      background: #fff; border: 1px solid #e1e4e8; padding: .6rem .8rem; border-radius: 6px;
      font-size: .82em; white-space: pre-wrap; min-height: 2em; margin: 0 0 .5rem;
      max-height: 8em; overflow-y: auto;
    }
    .answer-output .empty-msg { color: #6a737d; font-style: italic; }
    .answer-output .btn-row { display: flex; gap: .6rem; align-items: center; }
    .answer-output button {
      font-size: .82em; padding: .3rem .8rem; border-radius: 6px; cursor: pointer; border: none; font-weight: 600;
    }
    .answer-output .btn-copy { background: #1d63c9; color: #fff; }
    .answer-output .btn-copy:hover { background: #1550a8; }
    .answer-output .copy-result {
      font-size: .82em; color: #2da44e; opacity: 0; transition: opacity .3s;
    }
    .answer-output .copy-result.visible { opacity: 1; }
    .approval-actions {
      display: flex; align-items: center; gap: 1rem; justify-content: flex-end;
    }
    .approval-actions button {
      font-size: .95em; padding: .5rem 1.2rem; border-radius: 6px; cursor: pointer; border: none;
      font-weight: 600;
    }
    .approval-actions .btn-approve { background: #2da44e; color: #fff; }
    .approval-actions .btn-approve:hover { background: #218838; }
    .approval-actions .btn-reject { background: #fff; color: #d9534f; border: 1px solid #d9534f; }
    .approval-actions .btn-reject:hover { background: #fdf1f0; }
    /* 簡易シンタックスハイライト用トークン色（白基調前提。ダークモード分岐は持たせない） */
    pre .tok-com { color: #6a737d; font-style: italic; }
    pre .tok-str { color: #22863a; }
    pre .tok-ann { color: #b35900; }
    pre .tok-kw  { color: #8250df; font-weight: 600; }
    pre .tok-num { color: #0b7285; }
    pre .tok-type { color: #1d63c9; }
  </style>
</head>
<body>
  <h1>{タスクタイトル}</h1>
  <dl class="meta">
    <dt>ステータス</dt><dd><span class="status">Draft</span></dd>
    <dt>ブランチ</dt><dd><code>{new-branch}</code></dd>
    <dt>ベース</dt><dd><code>{base-branch}</code></dd>
    <dt>起票元</dt><dd>{URL or テキスト}</dd>
    <dt>作成日時</dt><dd>YYYY-MM-DD HH:MM:SS</dd>
  </dl>

  <!-- ============ 概要（常に展開・簡潔に） ============ -->
  <h2 class="section-title">概要</h2>

  <h3>背景 / やりたいこと</h3>
  <p>...（数行で）</p>

  <h3>ゴール</h3>
  <p>達成すべきこと・達成しないこと（スコープ外）を簡潔に。表形式が読みやすければ表を使う。</p>

  <!-- 確認事項があれば概要に目立つ形で配置。ブロッカーになり得るため埋もれさせない -->
  <h3 style="color:#d9534f;">確認事項（あれば）</h3>
  <div class="confirm">
    <strong>1. {確認したいこと}</strong><br>{背景・提案する既定値}
    <div class="comment-section">
      <div class="comment-form">
        <select onchange="updateAnswers()" data-label="確認事項 1">
          <option value="" disabled selected>-- 回答を選択 --</option>
          <option value="OK">OK（この方針で進めてよい）</option>
          <option value="修正必要">修正必要</option>
          <option value="質問あり">質問あり</option>
          <option value="__other__">その他（自由入力）</option>
        </select>
        <textarea placeholder="詳細を入力..." oninput="updateAnswers()" onchange="updateAnswers()"></textarea>
      </div>
    </div>
  </div>
  <!-- 確認事項が複数ある場合は .confirm を追加。番号とラベルを変える -->

  <h3>実装ステップ一覧（クリックで詳細）</h3>
  <button class="expand-all" type="button" onclick="document.querySelectorAll('details').forEach(d => d.open = true)">すべて展開</button>
  <button class="expand-all" type="button" onclick="document.querySelectorAll('details').forEach(d => d.open = false)">すべて折りたたむ</button>
  <ul class="toc">
    <li><a href="#impact">影響範囲</a> <span class="hook">— 変更対象ファイル・影響を受ける機能</span></li>
    <li><a href="#tech-policy">技術方針（調査結果）</a> <span class="hook">— 既存アーキテクチャと設計判断</span></li>
    <li><a href="#phase1">Phase 1: {小見出し}</a> <span class="hook">— 一言要約</span></li>
    <!-- Phase の数だけ追加 -->
    <li><a href="#test-policy">テスト方針（まとめ）</a></li>
  </ul>

  <!-- ============ 詳細（折りたたみ） ============ -->
  <h2 class="section-title" id="detail">詳細</h2>

  <details class="block" id="impact">
    <summary>影響範囲 <span class="hook">変更対象ファイル・影響を受ける機能</span></summary>
    <h4>変更対象ファイル</h4>
    <ul><li><code>path/to/file</code>: 変更内容</li></ul>
    <h4>影響を受ける機能</h4>
    <ul><li>...</li></ul>
  </details>

  <details class="block" id="tech-policy">
    <summary>技術方針（調査結果） <span class="hook">既存アーキテクチャと設計判断</span></summary>
    <p>既存実装の調査結果、採用する設計とその理由（既存パターンの転用元ファイル・行番号を明示する）。</p>
  </details>

  <details class="phase" id="phase1">
    <summary>Phase 1: {小見出し} <span class="hook">一言要約</span></summary>
    <ul><li>ステップ1</li><li>ステップ2</li></ul>
    <!-- 複雑な変更・既存パターン転用・新しい型定義を伴う場合は必ずサンプルコードを添える -->
    <pre><code>// path/to/File.kt（実装イメージ。実装時に既存コードとの整合を取る）
...
</code></pre>
    <div class="comment-section">
      <div class="comment-form">
        <textarea class="always-show" placeholder="コメントを入力..." data-label="Phase 1" oninput="updateAnswers()" onchange="updateAnswers()"></textarea>
      </div>
    </div>
  </details>
  <!-- Phase 2, 3... も同様に <details class="phase"> で追加。Phase のコメントは常にテキストエリア直表示 -->

  <details class="block" id="test-policy">
    <summary>テスト方針（まとめ）</summary>
    <ul><li>正常系・異常系・境界値のテストケース</li></ul>
  </details>

  <!-- 承認バー（回答コピー + 承認/修正） -->
  <div class="approval-bar">
    <div class="answer-output" id="answer-output">
      <pre id="answer-text"><span class="empty-msg">コメントを入力すると、ここに出力されます</span></pre>
      <div class="btn-row">
        <button class="btn-copy" type="button" onclick="copyAllAnswers()">回答をコピー</button>
        <span class="copy-result" id="copy-all-result"></span>
      </div>
    </div>
    <div class="approval-actions">
      <button class="btn-reject" type="button" onclick="sendApproval('reject')">修正要求</button>
      <button class="btn-approve" type="button" onclick="sendApproval('approve')">承認して実装開始</button>
    </div>
  </div>

  <script>
    // セレクトボックスの「その他」表示切替（確認事項用）
    document.querySelectorAll('.comment-form select').forEach(function (sel) {
      sel.addEventListener('change', function () {
        var ta = sel.closest('.comment-form').querySelector('textarea:not(.always-show)');
        if (!ta) return;
        if (sel.value === '__other__') { ta.classList.add('show'); ta.focus(); }
        else { ta.classList.remove('show'); ta.value = ''; }
      });
    });
    // 全コメント欄の回答を集約して出力エリアに反映
    function updateAnswers() {
      var title = document.title || 'プラン';
      var lines = [];
      // セレクトボックス（確認事項）
      document.querySelectorAll('.comment-form select').forEach(function (sel) {
        if (!sel.value) return;
        var label = sel.getAttribute('data-label');
        var ta = sel.closest('.comment-form').querySelector('textarea:not(.always-show)');
        var answer = sel.value === '__other__' ? (ta ? ta.value.trim() : '') : sel.value;
        if (answer) lines.push(label + ': ' + answer);
      });
      // テキストエリア直表示（Phase コメント）
      document.querySelectorAll('.comment-form textarea.always-show').forEach(function (ta) {
        var text = ta.value.trim();
        if (!text) return;
        var label = ta.getAttribute('data-label');
        lines.push(label + ': ' + text);
      });
      var pre = document.getElementById('answer-text');
      if (lines.length === 0) {
        pre.innerHTML = '<span class="empty-msg">コメントを入力すると、ここに出力されます</span>';
      } else {
        pre.textContent = '[' + title + ']\n' + lines.join('\n');
      }
    }
    function clipboardCopy(text) {
      var tmp = document.createElement('textarea');
      tmp.value = text;
      tmp.style.position = 'fixed';
      tmp.style.opacity = '0';
      document.body.appendChild(tmp);
      tmp.select();
      document.execCommand('copy');
      document.body.removeChild(tmp);
    }
    function copyAllAnswers() {
      var pre = document.getElementById('answer-text');
      var text = pre.textContent;
      if (!text || pre.querySelector('.empty-msg')) { alert('回答を選択してください'); return; }
      clipboardCopy(text);
      var result = document.getElementById('copy-all-result');
      result.textContent = 'Copied!';
      result.classList.add('visible');
      setTimeout(function () { result.classList.remove('visible'); }, 2000);
    }
    function sendApproval(type) {
      var title = document.title || 'プラン';
      var msg = type === 'approve'
        ? '[' + title + '] 承認: この方針で実装を開始してください'
        : '[' + title + '] 修正要求: ';
      if (type === 'reject') {
        var reason = prompt('修正内容を入力してください:');
        if (!reason) return;
        msg += reason;
      }
      clipboardCopy(msg);
      alert('コピーしました。チャットに貼り付けてください。');
    }
  </script>

  <script>
    // 依存なしの簡易シンタックスハイライト（CDN 不可のオフライン環境向け。Kotlin 以外の言語でも
    // キーワード配列を書き換えれば流用可）
    (function () {
      var KEYWORDS = ['fun','val','var','class','object','interface','enum','sealed','data','private',
        'public','protected','internal','open','abstract','override','return','when','if','else','for',
        'while','do','is','in','as','null','true','false','import','package','companion','by','const',
        'lateinit','this','super','inline','value','infix','operator','suspend','out','reified','where',
        'try','catch','finally','throw','init','get','set','vararg','typealias',
        'function','export','from','async','await','new','typeof','instanceof','void','delete',
        'let','type','readonly','extends','implements','static','abstract','yield','of',
        'switch','case','default','break','continue','debugger','with','do'];
      var KEYWORD_RE = new RegExp('\\b(' + KEYWORDS.join('|') + ')\\b', 'g');
      var TOKEN_RE = /(\/\/[^\n]*)|(\/\*[\s\S]*?\*\/)|("(?:[^"\\\n]|\\.)*")|(@[A-Za-z_][A-Za-z0-9_]*)|\b(\d+(?:\.\d+)?[fFlL]?)\b|\b([A-Z][A-Za-z0-9_]*)\b/g;
      function escapeHtml(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
      function highlight(src) {
        var escaped = escapeHtml(src);
        escaped = escaped.replace(TOKEN_RE, function (m, com, block, str, ann, num, type) {
          if (com) return '<span class="tok-com">' + com + '</span>';
          if (block) return '<span class="tok-com">' + block + '</span>';
          if (str) return '<span class="tok-str">' + str + '</span>';
          if (ann) return '<span class="tok-ann">' + ann + '</span>';
          if (num) return '<span class="tok-num">' + num + '</span>';
          if (type) return '<span class="tok-type">' + type + '</span>';
          return m;
        });
        var parts = escaped.split(/(<span[^>]*>[\s\S]*?<\/span>)/g);
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].indexOf('<span') === 0) continue;
          parts[i] = parts[i].replace(KEYWORD_RE, '<span class="tok-kw">$1</span>');
        }
        return parts.join('');
      }
      document.querySelectorAll('pre > code').forEach(function (block) {
        block.innerHTML = highlight(block.textContent);
      });
    })();
  </script>
</body>
</html>
```

**Phase 数が多い場合の TOC / `<details id="phaseN">` は Phase の数だけ機械的に増やす。**

書き出したらブラウザで開く:

```bash
# workspace_root / repo_name はここでも再計算する（シェル変数は Bash 呼び出しをまたいで残らない）
repo_toplevel="$(git rev-parse --show-toplevel)"
open "$(dirname "$repo_toplevel")/.claude-doc/$(basename "$repo_toplevel")/YYYYMMDD-HHMMSS-{branch-slug}.html"
```

ファイルパス（フルパス）をユーザーに報告する。

### Step 9: 承認の確認と修正サイクル

HTML を開いた状態でユーザーに承認可否を求める:

```
HTML プランをブラウザで開きました: <workspace_root>/.claude-doc/<repo_name>/YYYYMMDD-HHMMSS-xxx.html

この方針で実装を開始してよいですか？
- 承認: そのまま実装に進みます
- 修正要求: 指摘内容を反映して同じ HTML を更新します（再 open で確認）
```

- **承認**: Step 10 へ進む
- **却下/修正要求**: 指摘を反映して **同じ HTML ファイルを上書き更新**し、ブラウザに「再読み込みしてください」と案内する。必要なら Step 5/6/7 に戻って情報を補強する

**重要:** `EnterPlanMode` / `ExitPlanMode` は使わない。bypass permission モードのまま動作するため、承認後の実装フェーズで追加の許可プロンプトを挟まない。

### Step 10: 実装の開始

ユーザーから承認が得られたら、HTML 内のステータス表記を `Draft` → `In Progress` に更新（同じファイルを上書き）してから、引き続き実装を進める。

#### 10.1 Phase 選択

プランの「実装ステップ」セクションから Phase 一覧を抽出して提示し、開始 Phase を確認する（通常は Phase 1）:

```
プラン: {タスクタイトル}

Phase 1: {小見出し}  [未着手]
Phase 2: {小見出し}  [未着手]
...

どの Phase から実装を開始しますか？
```

#### 10.2 タスク登録と実装

選択された Phase のステップを `TaskCreate` で登録し、`in_progress` → `completed` で逐次進める。

実装時のルール:
- プロジェクトの `coding-general.md` / `coding-ddd.md` のルールを遵守する
- 影響範囲セクションに記載されたファイルを優先的に確認・編集する
- Phase 内の独立したステップは並行して実行する
- 大きな設計判断が必要な場合は `architect` エージェントへ委譲する

#### 10.3 Phase 完了時のレビュー

Phase 内の全ステップが完了したら、以下の2つのエージェントを **同時にバックグラウンドで起動** する:

- **code-reviewer**: コード品質、コーディングルール準拠、セキュリティ・パフォーマンス
- **qa-reviewer**: テスト網羅性（正常系・異常系・境界値）、テスト品質

両エージェントの結果を統合してユーザーに報告し、CRITICAL / HIGH の指摘があれば修正する。修正後、HTML プランの該当 Phase 見出しに完了マーク（例: `<h3>Phase 1: 認証基盤 <span class="status" style="background:#5cb85c;">完了</span></h3>`）を付け、同じ HTML を上書き更新する。

#### 10.4 次の Phase へ

未完の Phase があれば、続行するか確認する。すべて完了したら HTML 内のステータスを `Completed` に更新し、`/git-pr` での PR 作成を提案する。

---

## 中断・再開

途中で中断した場合は、既存の HTML プランファイルパスを指定して再開できる。HTML 内にステータスと Phase ごとの完了状況が記録されているため、続きから進められる。

```
このプランの Phase 2 から再開してください: /Users/okabe/workspace/henry-workspace/.claude-doc/henry-backend/20260510-180000-foo.html
```

のように Claude に直接指示すれば良い。

---

## 注意事項

- **未コミット変更がある状態では実行しない**: ブランチ切替時に変更が紛れ込むのを防ぐ
- **ブランチ名はユーザーから必ず確認する**: 自動生成しない
- **`EnterPlanMode` / `ExitPlanMode` は使わない**: cage + bypass permission 前提のため、プランモードに入ると追加の許可プロンプトが発生して開発体験が損なわれる
- **HTML プランの修正は上書き更新**: 修正サイクルで新規ファイルを作らず、同じファイルを上書きしてブラウザで再読み込みしてもらう
- **プランは `<workspace_root>/.claude-doc/<repo_name>/`（リポジトリの1つ上の階層）に集約する**: リポジトリ自身の `<cwd>/.claude-doc/` には置かない（書き込めない場合のフォールバックを除く）。複数リポジトリを横断する作業でもプランが一箇所にまとまる。ホームディレクトリ直下は sandbox 環境で書き込み権限エラーになることがあるため使わない
