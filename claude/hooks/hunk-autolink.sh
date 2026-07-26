#!/usr/bin/env bash
#
# SessionStart hook: hunk のライブレビューセッションが存在するときだけ、
# Claude に hunk-review skill と `hunk session` CLI の利用を促す指示を
# additionalContext としてコンテキストに注入する。
#
# 目的:
#   毎回「Load the Hunk skill...」と打たなくても、hunk 起動済みの状態で
#   Claude を立ち上げれば自動でレビュー連携モードに入れるようにする。
#
# 発火条件: hunk が存在し、かつライブセッションが 1 つ以上あるときのみ。
#   セッションが無ければ静かに何も出力せず終了する（通常セッションに影響しない）。

# hunk 未インストール環境では何もしない
command -v hunk >/dev/null 2>&1 || exit 0

# ライブセッション数を取得（失敗時は 0 とみなす）
session_count=$(hunk session list --json 2>/dev/null | jq -r '.sessions | length' 2>/dev/null || echo 0)
case "$session_count" in
  ''|*[!0-9]*) session_count=0 ;;
esac
[ "$session_count" -gt 0 ] || exit 0

# skill パスを取得できなければ連携指示を出せないので終了
skill_path=$(hunk skill path 2>/dev/null || true)
[ -n "$skill_path" ] || exit 0

read -r -d '' context <<EOF || true
A live Hunk review session is active (${session_count} session(s)).
Load the Hunk review skill at ${skill_path} and use the \`hunk session\` CLI commands
(hunk session list / get / review / navigate / comment) to inspect the diff and leave
inline review comments. Do NOT run interactive \`hunk diff\` / \`hunk show\` yourself --
the TUI belongs to the user; drive it only through \`hunk session\`.
EOF

jq -n --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
