---
name: ci-watch
description: |
  GitHub Actions の完了を待ち、CI 結果に応じて自動で fix → 再 push → 再 watch のループを回す。
  watch 中はトークン消費ゼロ (gh の long polling + run_in_background)。
  「/ci-watch」「CI 通った？」「CI 待って」「watch して」などの要求時に使用。
argument-hint: "[PR番号 (省略時は現在ブランチから推定)] [--no-loop で fail 時の自動 fix を無効化]"
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, Glob, Grep
---

# ci-watch スキル

GitHub Actions の完了を long polling で待ち、結果に応じて自動 fix → push → 再 watch のループを回す。

## 引数

- `[PR番号]` (省略可): 監視対象 PR。省略時は現在ブランチから `gh pr view --json number` で取得。
- `--no-loop` (省略可): 指定時は fail でループせず結果だけ報告して終了。

---

## 設計の前提と落とし穴

このスキルが解決したい根本課題は **「CI 完了まで long polling し、その間トークンを消費しない」** こと。Bash の `run_in_background: true` で gh コマンドをバックグラウンド実行し、harness の完了通知でエージェントが再起動する。

以下は試運転 (2026-06) で得た知見:

- **`--required` フラグの罠**: branch protection の required checks が未設定の PR で `gh pr checks --watch --required` を使うと「no required checks reported」で即 exit 0 を返す。**何も待たずに通過判定になる** ため、本スキルではデフォルト OFF。
- **`gh pr checks --watch --fail-fast`** (no `--required`) が最も安定。`skipping` は無視されて pass 判定、`failure` が 1 つでもあれば fail-fast で即時 exit。
- **push 直後の race**: push 完了から checks の作成までラグがある。`sleep 5` を挟むのが安全。
- **`--required` を使いたい場合**: branch protection の設定を事前確認できているケースだけ。デフォルトは外す。

---

## 実行フロー

### Step 1: 状態と PR の特定

並列で実行:

- `git rev-parse --is-inside-work-tree`
- `git branch --show-current`
- 引数で PR 番号未指定なら `gh pr view --json number,baseRefName --jq '.number'`

**中断条件**:
- git リポジトリ外: 「git リポジトリ内で実行してください」と報告して終了
- PR が見つからない: 「対象 PR を特定できませんでした。引数で PR 番号を指定してください」と報告して終了
- 現在ブランチが `main` / `master`: 「main / master 上では実行しないでください」と報告して終了

### Step 2: 現状スナップショット

`gh pr checks <PR>` を 1 回呼んで現状を取得:

```bash
gh pr checks <PR>
```

- すべて pass → 「既に全 check 通過済みです」と報告して終了 (watch しない)
- pending あり → step 3 に進む
- 既に fail → step 5b (失敗対応) に進む

### Step 3: Watch 起動 (background)

push 直後の場合は run 作成ラグ対策で `sleep 5` を入れる。`run_in_background: true` で起動して完了通知を待つ:

```bash
sleep 5
gh pr checks <PR> --watch --fail-fast 2>&1 | tail -40
echo "::EXIT::$?"
```

**重要**:
- `--required` は付けない (上記「設計の前提」参照)
- 必ず `2>&1 | tail -40` で出力を絞る (raw 進捗を全部受け取らない)
- `::EXIT::$?` でテキストとして exit code を埋め込む (Bash background だと exit code が見えにくいため)
- harness が「完了通知」を送る運用に乗っているので、ポーリングや sleep ループは **絶対に書かない**。完了通知が再起動のトリガー。

### Step 4: 完了通知を受け取る

harness が `<task-notification>` で再起動するので、output ファイルを tail で確認:

```bash
tail -30 <output-file>
```

- `::EXIT::0` → step 5a (PASS)
- `::EXIT::1` → step 5b (FAIL)

### Step 5a: PASS

- 「✅ CI 通過しました」と報告して終了
- pass した checks 名と所要時間を簡潔にまとめる (1 表で十分、log は出さない)

### Step 5b: FAIL — 失敗内容の取得

```bash
# 失敗した checks 一覧
gh pr checks <PR> --json name,state,link --jq '.[] | select(.state == "FAILURE" or .state == "CANCELLED") | "\(.name)\t\(.link)"'

# 最新失敗 run の log (tail で頭打ち)
latest_failed_run=$(gh run list --branch "$(git branch --show-current)" --status failure --limit 1 --json databaseId --jq '.[0].databaseId')
if [ -n "$latest_failed_run" ]; then
  gh run view "$latest_failed_run" --log-failed | tail -300
fi
```

- log は `tail -300` で頭打ち (巨大な失敗 log で context を埋めない)
- 「テスト失敗が複数 framework に散る」ケースは failed test 名を grep で抽出してから個別に詳細を取る
- 関心のない workflow (deploy / socket / claude review 等) の fail はループ対象外。

### Step 6: ループ判定

`--no-loop` 指定時は失敗報告だけして終了。

指定なしの場合は最大 3 回までループ:

1. 失敗内容を分析し、修正をエージェント自身で行う (Read / Edit / Write)
2. ユーザーに修正内容を提示し合意を取る (勝手に push しない)
3. ユーザー指示で `/git-cp` を呼ぶ (commit + push)
4. step 3 に戻る (再 watch)

**ループ上限**: 3 回。3 回連続で fail したらユーザーに判断を仰ぐ:
- 「3 回連続で CI が fail しています。手動介入が必要です。」
- 失敗 log と試した修正をまとめて報告。

### Step 7: 結果報告

PASS の場合:

```
✅ CI 通過しました ({回数}回目で通過)
- test / test: pass (10m44s)
- test / schema-reload: pass (6m5s)
...
```

FAIL かつループ上限の場合:

```
❌ CI が {回数}回連続で fail。手動介入が必要です。

最終失敗:
- {failed check 1}: {link}
- {failed check 2}: {link}

試した修正:
- {commit-sha 1}: {message}
- {commit-sha 2}: {message}

判断が必要な点:
- ...
```

---

## トークン消費の最小化指針

- **watch 中の polling は禁止**: 完了通知が来るまでファイルを読まない。`Bash(run_in_background: true)` の完了通知に任せる。
- **log は失敗時のみ**: pass のときは `gh run view --log` を呼ばない (大きい)。
- **failed log は `tail -300`**: 全体を読み込まない。
- **チェック名 list は `--json` + `--jq`**: 人間向け table 表示は冗長。
- **PR diff は取らない**: このスキルは CI 結果に集中する。コード理解は fix ターンで必要に応じて行う。

---

## 落とし穴 (本スキル外の文脈で動かす場合)

- **PR のスコープを誤認しない**: `gh pr checks <PR>` の PR 番号は引数で明示。git branch 名から推定する場合は `gh pr list --head $(git branch --show-current) --json number` で必ず確認。
- **手元未コミットがある状態でループしない**: fix ターン開始時に `git status --porcelain` を確認。stash されていない手元変更があれば、それを取り込むか確認してから進む。
- **メイン / master では実行しない**: `git branch --show-current` が `main` / `master` なら中断。CI 失敗対応が破壊的影響を持ちうる。
- **不要な workflow を見ない**: `claude / claude` や `Socket Security` など、本来のテストと無関係な workflow が並んでいる。failed log を取るときは「test / test」「scenario-test / test」など PR の品質に関わる workflow に絞ること。
- **CI fail を握りつぶさない**: 失敗テストを `xtest` 化して通すような fix は禁止。根本原因を直す。

---

## このスキルが向かない用途

- **長時間の CI 監視 (1 時間超)**: 完了通知ベースだが、harness 側でタイムアウトする可能性。30 分以上かかる CI には `--no-loop` で 1 回だけ watch し、結果通知後にユーザーが判断する運用が安全。
- **flaky テストの自動 retry**: 「同じテストが時々失敗する」を retry で隠すと根本原因が埋もれる。flaky を検出したら自動 fix せずユーザーに報告。
- **テスト結果以外の原因で failing する CI**: deploy 系・lint 系の fail は fix の方針が異なる。failed check 名で分岐して対応する (lint なら ./gradlew detekt、test なら test 修正、deploy なら確認のみ)。
