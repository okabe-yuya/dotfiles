---
name: plan
description: |
  実装方針のプランを計画し、.plansディレクトリにMarkdownファイルとして出力する。
  「/plan」「プランを立てて」「実装計画を作成」「設計を考えて」などの要求時に使用。
  Notion URLを渡すと、関連情報を取得して計画に反映する。
argument-hint: "[Notion URL (optional)] [タスク説明]"
user-invocable: true
allowed-tools: Read, Write, Glob, Grep, Bash(date *), Bash(mkdir *), Bash(ls *), Bash(test *)
---

# プランニングスキル

実装方針のプランを計画し、Markdownファイルとして出力するスキル。

## 実行フロー

### Step 1: 出力先ディレクトリの確認

まず `~/.claude/.plans/` ディレクトリの存在を確認する。

```bash
test -d ~/.claude/.plans
```

**ディレクトリが存在しない場合:**
- 以下の警告メッセージを出力して処理を中断する：

```
⚠️ エラー: プラン出力先ディレクトリが存在しません

.plansディレクトリを作成してください：
  mkdir -p ~/.claude/.plans

作成後、再度 /plan を実行してください。
```

### Step 2: 入力の解析

引数を解析し、以下を判定：
- Notion URLの有無（`https://notion.so/` または `https://www.notion.so/` で始まるURL）
- タスク説明テキスト

### Step 3: Notion連携（URLがある場合）

Notion URLが渡された場合、`mcp__claude_ai_notion__notion-fetch` を使用してページ内容を取得する。

```
ToolSearch で "select:mcp__claude_ai_notion__notion-fetch" を実行してツールをロード
↓
mcp__claude_ai_notion__notion-fetch でページ内容を取得
```

**取得に失敗した場合:**
- 以下のメッセージを出力して処理を中断する：

```
⚠️ エラー: Notionページの取得に失敗しました

URL: {URL}
理由: {エラー内容}

URLが正しいか、アクセス権限があるか確認してください。
```

### Step 4: コードベースの調査

タスクに関連するコードベースを調査する：
- 関連ファイルの特定（Glob, Grep）
- 既存の実装パターンの確認（Read）
- 依存関係の把握

### Step 5: 質問と確認

プラン作成に必要な情報が不足している場合、ユーザーに質問する：
- 技術的な選択肢がある場合の優先度
- 要件の曖昧な部分の明確化
- 制約条件の確認

### Step 6: プラン作成

テンプレート（`~/.claude/skills/plan/templates/plan-template.md`）に従ってプランを作成する。

### Step 7: ファイル出力

作成したプランを以下の形式でファイル出力：

**出力先:** `~/.claude/.plans/`
**ファイル名:** `YYYYMMDD-HHMMSS-{日本語タイトル}.md`

```bash
# 現在日時の取得
date "+%Y%m%d-%H%M%S"
```

### Step 8: 完了報告

出力したファイルパスとプランの概要を報告する。

---

## イテレーション対応

プランに「確認事項」セクションがある場合、ユーザーが回答後に再度 `/plan` を実行すると：

1. 既存のプランファイルを読み込む
2. 確認事項への回答を反映
3. プランを更新して同じファイルに上書き保存

---

## 注意事項

- プランは実装の指針であり、実際の実装は別途行う
- 確認事項は必ずチェックボックス形式（`- [ ]`）で記述する
- 技術的な判断が必要な箇所は明示的に選択肢を提示する
