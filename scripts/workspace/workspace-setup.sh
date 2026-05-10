#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

# キーコード: 1=18, 2=19, 3=20, 4=21, 5=23, 6=22, 7=26, 8=28, 9=25
KEYCODES=(18 19 20 21 23 22 26 28 25)

# ============================================
# ヘルパー関数
# ============================================

usage() {
    echo "Usage: $(basename "$0") <template_name> [--fresh]"
    echo ""
    echo "Options:"
    echo "  --fresh    対象アプリを一度終了してから起動する"
    echo ""
    echo "利用可能なテンプレート:"
    yq '.templates | keys | .[]' "$CONFIG_FILE" | sed 's/^/  - /'
    exit 1
}

check_dependencies() {
    local missing=()

    if ! command -v yq &>/dev/null; then
        missing+=("yq (brew install yq)")
    fi
    if ! command -v cliclick &>/dev/null; then
        missing+=("cliclick (brew install cliclick)")
    fi
    if ! command -v osascript &>/dev/null; then
        missing+=("osascript (macOS標準)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: 以下のコマンドが見つかりません:" >&2
        for m in "${missing[@]}"; do
            echo "  - $m" >&2
        done
        exit 1
    fi
}

# Mission Controlを開いてデスクトップを必要数まで追加する
ensure_desktops() {
    local target_count="$1"

    osascript -l JavaScript <<EOF
const se = Application("System Events");
const targetCount = ${target_count};

// Mission Controlを起動
se.keyCode(160); // Mission Control キー (F3相当)
delay(1);

const mcProcess = se.processes.byName("Dock");
const mcGroup = mcProcess.groups.byName("Mission Control");
const spacesBar = mcGroup.groups.at(0).groups.byName("Spaces Bar");
const spacesList = spacesBar.lists.at(0);
const addButton = spacesBar.buttons.at(0);

let currentCount = spacesList.buttons.length;

let retries = 0;
const maxRetries = 3;
while (currentCount < targetCount && retries < maxRetries) {
    se.click(addButton);
    delay(0.5);
    const newCount = spacesList.buttons.length;
    if (newCount === currentCount) {
        retries++;
        delay(0.5);
    } else {
        currentCount = newCount;
        retries = 0;
    }
}

// Mission Controlを閉じる
se.keyCode(53); // ESC
delay(0.5);

if (currentCount < targetCount) {
    throw new Error("デスクトップの追加に失敗しました (現在: " + currentCount + ", 目標: " + targetCount + ")");
}
EOF
}

# 指定デスクトップに切り替える
switch_desktop() {
    local desktop_index="$1"
    local kc="${KEYCODES[$((desktop_index - 1))]}"

    osascript -l JavaScript <<EOF
const se = Application("System Events");
se.keyCode(${kc}, { using: "control down" });
delay(0.5);
EOF
}

# マウスカーソルを移動してモニターにフォーカスを当てる
focus_monitor() {
    local cursor_x="707"
    local cursor_y="422"

    if [[ "$cursor_x" == "null" ]] || [[ -z "$cursor_x" ]]; then
        return
    fi

    cliclick "m:${cursor_x},${cursor_y}"
    sleep 0.3
}

# アプリを安全に終了する
quit_app() {
    local app_name="$1"

    osascript <<EOF
tell application "${app_name}"
    if it is running then
        quit
    end if
end tell
EOF
    sleep 0.5
}

# アプリを起動してフォーカスを当てる
launch_app() {
    local app_name="$1"

    if ! open -a "${app_name}" 2>/dev/null; then
        echo "  Warning: ${app_name} が見つかりません。スキップします" >&2
        return
    fi
    sleep 1
}

# ============================================
# メイン処理
# ============================================

TEMPLATE_NAME=""
FRESH_MODE=false

for arg in "$@"; do
    case "$arg" in
        --fresh) FRESH_MODE=true ;;
        -*) echo "Error: 不明なオプション: $arg" >&2; usage ;;
        *) TEMPLATE_NAME="$arg" ;;
    esac
done

if [[ -z "$TEMPLATE_NAME" ]]; then
    usage
fi

check_dependencies

# テンプレートの存在確認
if [[ "$(yq ".templates.${TEMPLATE_NAME}" "$CONFIG_FILE")" == "null" ]]; then
    echo "Error: テンプレート '${TEMPLATE_NAME}' が見つかりません" >&2
    echo ""
    usage
fi

echo "ワークスペース '${TEMPLATE_NAME}' をセットアップします..."

# テンプレートで使用するモニター一覧を取得
monitor_keys=$(yq ".templates.${TEMPLATE_NAME}.monitors | keys | .[]" "$CONFIG_FILE")

for monitor_key in $monitor_keys; do
    echo ""
    monitor_desc=$(yq ".monitors.${monitor_key}.description" "$CONFIG_FILE")
    echo "=== ${monitor_desc} (${monitor_key}) ==="

    # モニターにフォーカスを移す
    cursor_x=$(yq ".monitors.${monitor_key}.cursor_x" "$CONFIG_FILE")
    cursor_y=$(yq ".monitors.${monitor_key}.cursor_y" "$CONFIG_FILE")
    focus_monitor "$cursor_x" "$cursor_y"

    # 必要なデスクトップ数を確認・作成
    desktop_count=$(yq ".templates.${TEMPLATE_NAME}.monitors.${monitor_key}.desktops | length" "$CONFIG_FILE")
    echo "  デスクトップ数: ${desktop_count}"
    ensure_desktops "$desktop_count"

    # 各デスクトップにアプリを配置
    for ((i = 0; i < desktop_count; i++)); do
        desktop_num=$((i + 1))
        echo "  デスクトップ ${desktop_num}:"

        # デスクトップに切り替え
        switch_desktop "$desktop_num"

        # アプリ一覧を取得して起動
        app_count=$(yq ".templates.${TEMPLATE_NAME}.monitors.${monitor_key}.desktops[${i}].apps | length" "$CONFIG_FILE")
        for ((j = 0; j < app_count; j++)); do
            app_name=$(yq ".templates.${TEMPLATE_NAME}.monitors.${monitor_key}.desktops[${i}].apps[${j}]" "$CONFIG_FILE")

            if [[ "$FRESH_MODE" == true ]]; then
                quit_app "$app_name"
            fi

            echo "    -> ${app_name}"
            launch_app "$app_name"
        done
    done
done

# メインモニターのデスクトップ1に戻る
main_cursor_x=$(yq ".monitors.main.cursor_x" "$CONFIG_FILE")
if [[ "$main_cursor_x" != "null" ]] && [[ -n "$main_cursor_x" ]]; then
    main_cursor_y=$(yq ".monitors.main.cursor_y" "$CONFIG_FILE")
    focus_monitor "$main_cursor_x" "$main_cursor_y"
fi
switch_desktop 1

echo ""
echo "セットアップ完了!"
