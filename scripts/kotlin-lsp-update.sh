#!/usr/bin/env bash
set -euo pipefail

# kotlin-lsp (JetBrains 公式・pre-alpha) を JetBrains CDN から最新ビルドへ貼り替える。
# macOS 専用 (Apple Silicon / Intel)。
#
# 背景 (なぜ brew でなく自前管理か):
#   kotlin-lsp のビルドには「約30日で失効する時限」(起動時に
#   "This build of intellij-server has expired." で落ちる) が、全配布物
#   (brew / 公式 zip / .sit / VS Code 拡張) に等しく埋め込まれている。失効しない
#   恒久版は存在しないため、月イチでフレッシュなビルドへ貼り替える運用が前提になる。
#   本スクリプトはその貼り替えを brew 非依存の 1 コマンドに畳み、更新元・展開先・
#   PATH 上の実体を dotfiles 側で完全に掌握する。
#
#   nvim 側は既に設定済み (lua/plugins/lsp.lua で kotlin_lsp を enable、lspconfig
#   preset が cmd = { 'kotlin-lsp', '--stdio' } を供給)。本スクリプトは PATH 上に
#   「期限内の kotlin-lsp」を用意するだけでよい。
#
# step:
#   1. GitHub の releases/latest リダイレクトから最新バージョンを解決する
#   2. 既に最新なら skip する (--force で強制再取得)
#   3. JetBrains CDN から macOS 用スタンドアロン (.sit = zip 互換) を取得し SHA-256 検証
#   4. 一時領域へ展開・launcher 検証してから、既存を安全に差し替える (quarantine 除去)
#   5. ~/.local/bin/kotlin-lsp を launcher (bin/intellij-server、無ければ kotlin-lsp.sh) へ貼り替える
#   6. 古い世代を prune する (現行 + 最新 KEEP_GENERATIONS 世代を残す)
#
# 使い方:
#   scripts/kotlin-lsp-update.sh          # 最新へ更新 (既に最新なら何もしない)
#   scripts/kotlin-lsp-update.sh --force  # 同一バージョンでも再取得・再展開

GITHUB_LATEST="https://github.com/Kotlin/kotlin-lsp/releases/latest"
CDN_BASE="https://download.jetbrains.com/language-server/kotlin-server"
INSTALL_ROOT="$HOME/.local/share/kotlin-lsp"
BIN_DIR="$HOME/.local/bin"
BIN_LINK="$BIN_DIR/kotlin-lsp"
# 貼り替え直後のロールバック用に、現行含め最新2世代を保持する
KEEP_GENERATIONS=2

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
info() { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}!${RESET} %s\n" "$1"; }
die()  { printf "  ${RED}✗ %s${RESET}\n" "$1" >&2; exit 1; }

# macOS 専用 (uname -m だけでは Linux が .sit 経路に入り込むため OS も見る)
[ "$(uname -s)" = "Darwin" ] || die "macOS 専用スクリプトです (uname -s=$(uname -s))"

# 引数解釈 (未知の引数は 360MB DL 前に弾く)
FORCE=0
case "${1:-}" in
  "")      ;;
  --force) FORCE=1 ;;
  *)       die "不明な引数: $1 (使い方: $(basename "$0") [--force])" ;;
esac

# arch → CDN のファイル名 suffix (Apple Silicon は -aarch64、Intel は無印)
case "$(uname -m)" in
  arm64)  SUFFIX="-aarch64" ;;
  x86_64) SUFFIX="" ;;
  *)      die "未対応の arch: $(uname -m)" ;;
esac

# 1. 最新バージョンを解決する。releases/latest のリダイレクト先 tag から取り出すことで
#    GitHub API (未認証 60req/h の rate limit) と python3 依存の両方を避ける。
tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$GITHUB_LATEST")" \
  || die "GitHub から最新リリースを解決できなかった"
tag="${tag##*/tag/}"          # .../releases/tag/kotlin-lsp/v263.4702.0 → kotlin-lsp/v263.4702.0
version="${tag#kotlin-lsp/v}" # → 263.4702.0
# 外部入力なので rm -rf / URL に埋める前にバージョン形式を検証する
[[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]] || die "想定外のバージョン形式: $version (tag=$tag)"

# 2. 既に最新かを判定する。dangling symlink や INSTALL_ROOT 配下でない symlink
#    (旧 brew 版を手で link した等) は「現行不明」として新規インストール扱いにする。
current=""
if [ -L "$BIN_LINK" ] && [ -e "$BIN_LINK" ]; then
  target="$(readlink "$BIN_LINK")"
  # symlink 先が INSTALL_ROOT 配下と確定しているので、パラメータ展開で先頭要素=version を取る
  case "$target" in
    "$INSTALL_ROOT"/*) rel="${target#"$INSTALL_ROOT"/}"; current="${rel%%/*}" ;;
  esac
fi
if [ "$current" = "$version" ] && [ "$FORCE" -eq 0 ]; then
  info "既に最新 (v$version)。更新不要 (--force で再取得)"
  exit 0
fi
if [ -n "$current" ]; then
  printf "  更新: v%s → v%s\n" "$current" "$version"
else
  printf "  新規インストール: v%s\n" "$version"
fi

# 3. ダウンロード + SHA-256 検証
asset="kotlin-server-${version}${SUFFIX}.sit"
url="$CDN_BASE/$version/$asset"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
printf "  … %s を取得中\n" "$asset"
curl -fSL --progress-bar "$url" -o "$tmp/$asset"
curl -fsSL "$url.sha256" -o "$tmp/$asset.sha256"
# .sha256 は "<hash> *<filename>" 形式。hash 部分 (第1フィールド) だけ突合する
expected="$(awk '{print $1}' "$tmp/$asset.sha256")"
actual="$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')"
[ "$expected" = "$actual" ] || die "SHA-256 不一致 (expected=$expected actual=$actual)"
info "SHA-256 検証 OK"

# 4. 一時領域へ展開し launcher を検証してから、現行を atomic に差し替える。
#    先に現行を消すと、展開失敗や中断で dangling が残り、稼働中プロセスの実体も抜いてしまう。
#    (.sit は PK ヘッダの zip 互換アーカイブ。macOS には ditto が必ず在るので単独で使う)
ex="$tmp/extract"
ditto -x -k "$tmp/$asset" "$ex"
# launcher を探す。kotlin-lsp.sh は将来削除予定 (起動時に deprecation warning が出る) のため
# bin/intellij-server を優先し、無ければ kotlin-lsp.sh にフォールバックする。
# どちらも `--stdio` を受け付けるので nvim 側の cmd = { 'kotlin-lsp', '--stdio' } は不変。
launcher_ex="$(find "$ex" -type f -path '*/bin/intellij-server' -print -quit)"
[ -n "$launcher_ex" ] || launcher_ex="$(find "$ex" -type f -name 'kotlin-lsp.sh' -print -quit)"
[ -n "$launcher_ex" ] || die "launcher (bin/intellij-server か kotlin-lsp.sh) が展開物に見つからない"

dest="$INSTALL_ROOT/$version"
mkdir -p "$INSTALL_ROOT"
# 既存 (--force で同一版) は退避してから移し、mv が失敗しても現行を無傷で残す
backup=""
if [ -e "$dest" ]; then
  backup="${dest}.old.$$"
  rm -rf "$backup"
  mv "$dest" "$backup"
fi
mv "$ex" "$dest"
if [ -n "$backup" ]; then
  rm -rf "$backup"
fi
# 展開物の基点 (一時領域 → 本設置先) を差し替えて launcher の実パスを得る
launcher="$dest/${launcher_ex#"$ex"/}"
chmod +x "$launcher"
# Gatekeeper の隔離属性を落とし、起動のたびに確認ダイアログが出るのを防ぐ
xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true
info "展開 OK: $dest"

# 5. PATH 上の実体を新バージョンへ貼り替える
#    JetBrains 公式手順どおり symlink 方式 (launcher は自身の実パスを解決して JBR を探す)
mkdir -p "$BIN_DIR"
ln -sfn "$launcher" "$BIN_LINK"
info "symlink: $BIN_LINK → $launcher"

# 6. 古い世代を prune する。現行 version は必ず残し、それ以外を古い順に
#    総数が KEEP_GENERATIONS になるまで削除する (mapfile は bash4+ 専用なので使わない)。
all_versions=()
while IFS= read -r v; do
  all_versions+=("$v")
# 末尾スラッシュで INSTALL_ROOT が symlink でも中を辿る (BSD find の -P 既定対策)
done < <(find "$INSTALL_ROOT/" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V)
remaining=${#all_versions[@]}
# bash 3.2 の set -u では空配列の "${a[@]}" が unbound になるため +展開で守る
for v in ${all_versions[@]+"${all_versions[@]}"}; do
  [ "$remaining" -le "$KEEP_GENERATIONS" ] && break
  [ "$v" = "$version" ] && continue   # 現行は保護する
  rm -rf "${INSTALL_ROOT:?}/$v"
  warn "旧世代を削除: v$v"
  remaining=$((remaining - 1))
done

# PATH 検証: 実際に起動される kotlin-lsp が本スクリプト管理下でなければ警告する
# (旧 brew 版の残存や ~/.local/bin が PATH に無いケースを実行時に検知する)
resolved="$(command -v kotlin-lsp || true)"
if [ "$resolved" != "$BIN_LINK" ]; then
  warn "PATH 上の kotlin-lsp は $BIN_LINK ではなく ${resolved:-（見つからない）} です"
  warn "  ~/.local/bin を PATH の先頭側に置くか、旧 brew 版を削除してください (brew uninstall kotlin-lsp)"
fi

printf "\n${GREEN}✨ kotlin-lsp v%s に更新しました${RESET}\n" "$version"
printf "  実体: %s\n" "$(readlink "$BIN_LINK")"
printf "  失効したら再実行: %s\n" "scripts/kotlin-lsp-update.sh"
