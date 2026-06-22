---
name: dev-cycle
description: |
  /start で実装を開始し、/review でセルフレビュー、ユーザー確認後に /git-cp でコミット&push、
  PR 未作成なら /git-pr、最後に /ci-watch で CI 完了を待つ「機能開発フロー」を 1 コマンドで回す。
  CI fail 時の fix → 再 push → 再 watch のループは /ci-watch 側に任せる。
  「/dev-cycle」「機能開発フロー」「開発サイクル」などの要求時に使用。
argument-hint: "[ベースブランチ] [Linear/Notion URL (省略可)] [--prompt で半手動モード]"
user-invocable: true
allowed-tools: Skill, AskUserQuestion, Bash, Read, Edit, Write, Glob, Grep
---

# dev-cycle スキル

機能開発の「実装 → セルフレビュー → コミット → PR → CI 緑化」までを 1 コマンドで回す **オーケストレーション** スキル。各ステップは既存スキル (`/start` / `/review` / `/git-cp` / `/git-pr` / `/ci-watch`) を順に呼ぶだけで、本スキル本体に固有のロジックはほぼ持たない。

## 引数

- `[ベースブランチ]` (必須): `/start` と `/git-pr` に渡す。例: `develop` / `master` / 親 feature branch
- `[Linear/Notion URL]` (省略可): `/start` に渡す実装計画の参照先
- `--prompt` (省略可): 半手動モード。各ステップ前に「次に X を実行します」と案内して停止。デフォルトは自動進行

---

## 設計の前提と非ゴール

### このスキルが解決したい課題

- 機能開発の典型フローを「次は何だっけ?」を考えずに回したい
- 各サブスキル (/start, /review, /git-cp, /git-pr, /ci-watch) はそれぞれ役割が明確だが、つなぎ目で人手判断が挟まる
- 特に **CI fail → fix → push → watch** のループはミスしやすい

### 非ゴール

- **コードを書くロジックは持たない**: 実装ターンはユーザーとエージェントの対話で進む
- **無限ループの管理は /ci-watch に任せる**: 本スキル外側で独自ループを回すと **二重ループで無限化リスク**
- **flaky test の自動 retry はしない**: 同じテストが連続 fail したらユーザー判断
- **deploy 系の失敗には立ち入らない**: テスト / lint の失敗のみ自動 fix 候補

---

## 絶対ルール: sub-skill は必ず `Skill` ツールで呼ぶ

dev-cycle は **オーケストレータ** であり、ロジックは各 sub-skill (`/start` / `/review` / `/git-cp` / `/git-pr` / `/ci-watch`) に閉じている。本スキルが独自判断で sub-skill の処理を **Bash / Edit / Write 等で代替してはならない**。

### 禁止事項

- `Skill: start` の代わりに `git checkout -b ...` を直接実行する
- `Skill: review` の代わりに `git diff` + 目視で済ます
- `Skill: git-cp` の代わりに `git add` / `git commit` / `git push` を直接実行する
- `Skill: git-pr` の代わりに `gh pr create` を直接実行する
- 「小さい変更だから」「既に方針合意済みだから」を理由に sub-skill を skip する

### なぜ必須か

- 各 sub-skill には独自の安全装置・規約・命名ルール・hook がある。bypass すると統一性が崩れ、ユーザーが期待する観点 (lint / 重複 check / message format 等) が抜ける
- dev-cycle の表面挙動だけ真似て中身を変えるのは「sub-skill を更新しても dev-cycle 経由では効かない」という剥離を生む
- 判断揺らぎ・ステップ抜けの再発を防ぐため、各 step での Skill 呼び出しは **省略不可**

### スキップしたい場合

`--prompt` (半手動モード) で当該 step を「スキップする」と明示的にユーザーが選択した場合に限り、Skill 呼び出しを省く。本スキル側の自己判断では skip しない。

---

## 実行フロー

### Step 1: 状態確認

```bash
git rev-parse --is-inside-work-tree
git branch --show-current
```

**中断条件**:
- git リポジトリ外 → 終了
- `main` / `master` ブランチ上 → 「base ブランチ上では実行しないでください」と終了
- 作業中の未コミット変更あり → ユーザーに stash するか確認

### Step 2: /start で実装計画

```
Skill: start
args: <ベースブランチ> <Linear/Notion URL>
```

`/start` がベースブランチを最新化して新規ブランチを作成し、実装計画 HTML を生成。ユーザー承認後に実装ターンに入る。

### Step 3: 実装ターン

ユーザーとエージェントの対話で実装を進める。コード変更が一段落した段階で次へ。

**判断軸**:
- ユーザーが「実装完了」相当の合図 (「ok」「完了」「次へ」等) を出したら step 4 へ
- 未コミット変更があることを `git status --porcelain` で確認 (なければ step 7 まで skip)

### Step 4: /review でセルフレビュー

```
Skill: review
args: (現ブランチ全体)
```

**結果の解釈 (Blocker 判定)**:
- 🔴 **Must** が 1 件でもあれば: 修正ターンに入る (Step 4 ループ)
- 🟠 **Should** / 🟡 **Suggest** / 🟢 **Nit** のみ: そのまま step 5 に進む (修正は次回 PR / follow-up)
- 指摘なし: step 5 に進む

**Blocker 解消ループ**: 最大 3 回。3 回連続で Must が解消しなければユーザーに判断を仰ぐ:
> 「3 回 fix → review を回しましたが Blocker が残っています。手動介入が必要です」

### Step 5: ユーザー確認 (この 1 箇所のみ)

```
AskUserQuestion:
  "セルフレビュー OK。このまま /git-cp で commit & push → CI watch に進みますか？"
  options:
    - "進む (Recommended)"
    - "もう少し直したい (実装ターンに戻る)"
    - "中断する"
```

**中断 / 戻り**:
- 「もう少し直したい」 → step 3 (実装ターン) に戻る
- 「中断する」 → 終了。差分は手元に残す

### Step 6: /git-cp で commit & push

```
Skill: git-cp
```

`/git-cp` 側で fixup / 新規 commit 判定、コミットメッセージ生成、push まで完結。

**例外処理**:
- 「コミット対象なし」と返ってきた場合 → step 7 へ進む (push 済み state)
- push 失敗 (non-fast-forward) → 報告して終了

### Step 7: PR 確認 / 作成

```bash
# 現ブランチに紐づく PR があるか
gh pr view --json number,state --jq '.number, .state'
```

- PR 既存 (state=OPEN): step 8 (ci-watch) へ
- PR なし or CLOSED: `/git-pr` を呼ぶ

```
Skill: git-pr
args: <ベースブランチ>
```

### Step 8: /ci-watch

```
Skill: ci-watch
args: <PR番号>
```

`/ci-watch` 側で background 起動・完了通知・fail 時の fix → 再 push → 再 watch ループ (最大 3 回) を担当。

**本スキルは結果を 1 回受け取って終了**:
- ✅ PASS → 結果報告して終了
- ❌ FAIL at max retry → /ci-watch からの報告をそのまま伝えて終了 (本スキル側で再ループしない)

### Step 9: 結果報告

```
✅ dev-cycle 完了

- ブランチ: {現ブランチ}
- PR: {PR URL}
- コミット数: {n}
- CI: {PASS / FAIL (詳細)}
- 所要時間: {実装〜CI 通過まで}
```

---

## 半手動モード (`--prompt`)

各 step の手前で次のアクションをユーザーに案内して停止する:

```
AskUserQuestion:
  "次は /review を実行します。進めますか？"
  options:
    - "進む"
    - "スキップする"
    - "中断する"
```

「スキップする」を選んだら次の step に進む (review を飛ばして git-cp に行く等)。

---

## 落とし穴

- **二重ループ禁止**: `/ci-watch` 自体が内部で fix → push → watch を最大 3 回ループする。dev-cycle 側で再度 step 4-8 を回すと最大 9 回ループになり無限化リスク。**1 回の `/ci-watch` 呼び出しを最終アクション**として扱う。
- **/review の判定揺らぎ**: Blocker 判定は AI の出力解釈に依存。`### ❌ ルール違反` / `🔴 Must` の出現を grep で確認するなど、堅牢な判定基準を持つ。
- **未コミット変更の取り込み忘れ**: step 3 実装ターン後に `git status --porcelain` で必ず未コミット確認。差分なしなら step 4-6 を skip。
- **PR base の取り違え**: `/git-pr` のベースは引数で渡したベースブランチ。stack 戦略のときは「親 feature branch」を指す。dev-cycle 起動時の引数を最後まで保持。
- **Linear / Notion URL の引き継ぎ**: `/start` には渡すが、後続のステップでは引き継がない (各サブスキルがコミット message や PR description に必要に応じて含める)。
- **state file は作らない**: PR 番号やブランチ名は `gh pr view` / `git branch --show-current` で都度取り直す。harness 再起動で context が失われても復元可能にする。

---

## このスキルが向かない用途

- **Hotfix**: `/git-hotfix` を直接使う。dev-cycle は新規実装フロー向け
- **複数 PR を跨ぐ大規模変更**: PR 分割の判断が必要。dev-cycle は 1 PR で完結するスコープ向け
- **インフラ / 設定変更のみ**: テスト / lint が中心の CI なので、deploy 系の変更は別フロー (手動 review 重視) で
- **既存 PR の修正**: dev-cycle の中間 (step 3 以降) からの再開は対応していない。状況に応じて個別スキルを直接呼ぶ
- **探索的実装**: 「何を作るか確定していない」段階では `/start` の計画フェーズだけ使う方が良い

---

## 既存スキルとの境界

| スキル | 責務 | dev-cycle での扱い |
|--------|------|---|
| `/start` | ベース最新化 + 新ブランチ + 計画 HTML | step 2 で呼ぶ |
| `/review` | セルフレビュー | step 4 で呼ぶ |
| `/git-cp` | commit + push | step 6 で呼ぶ |
| `/git-pr` | PR 作成 | step 7 で PR 未作成時のみ呼ぶ |
| `/ci-watch` | CI 完了待ち + fail 時の fix-loop | step 8 で呼ぶ (1 回のみ) |

dev-cycle は **これらを順に呼ぶオーケストレータ** であり、固有のロジックは「Blocker 解消ループ (max 3)」と「ユーザー確認 1 箇所」と「半手動モード」のみ。
