#!/usr/bin/env bash
#
# Stop hook: 直前のアシスタントの返答が英語で書かれていたら止めて、日本語で書き直させる。
#
# 目的:
#   長いセッションの後半やサブエージェントの結果を要約するときに英語へ戻ることがあるため、
#   返答を書き終えた時点で機械的に検知して差し戻す。
#
# 判定:
#   - 直前のユーザーの発言以降に書かれたアシスタントのテキストを集める（ツールの結果は含めない）
#   - コードブロック・インラインコード・URL を除いた本文で、仮名・漢字と英字の数を数える
#   - 英字が MIN_LETTERS 未満の短い返答は判定しない（URL やコマンドだけの返答で誤検知しないため）
#   - 仮名・漢字の割合が JA_RATIO 未満なら英語とみなして block する
#   - 差し戻した直後の再停止（stop_hook_active=true）では判定しない（無限ループを防ぐため）

exec python3 -c '
import json, re, sys

MIN_LETTERS = 40
JA_RATIO = 0.2

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if payload.get("stop_hook_active"):
    sys.exit(0)

path = payload.get("transcript_path")
if not path:
    sys.exit(0)

texts = []
try:
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except Exception:
                continue
            message = entry.get("message") or {}
            content = message.get("content")
            if entry.get("type") == "user":
                # ツールの結果だけの user エントリは発言ではないので区切りにしない
                if isinstance(content, str) or (
                    isinstance(content, list)
                    and any(isinstance(b, dict) and b.get("type") == "text" for b in content)
                ):
                    texts = []
            elif entry.get("type") == "assistant" and isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        texts.append(block.get("text", ""))
except Exception:
    sys.exit(0)

body = "\n".join(texts)
body = re.sub(r"```.*?```", " ", body, flags=re.S)
body = re.sub(r"`[^`]*`", " ", body)
body = re.sub(r"https?://\S+", " ", body)

letters = len(re.findall(r"[A-Za-z]", body))
japanese = len(re.findall(r"[぀-ヿ㐀-鿿]", body))

if letters < MIN_LETTERS:
    sys.exit(0)
if japanese / (japanese + letters) >= JA_RATIO:
    sys.exit(0)

print(json.dumps({
    "decision": "block",
    "reason": "直前の返答が英語で書かれています。ユーザーへの返答は日本語で書き直してください（コード・識別子・コマンドはそのままでよい）。",
}, ensure_ascii=False))
'
