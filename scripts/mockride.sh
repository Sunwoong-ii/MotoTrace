#!/usr/bin/env bash
#
# Mock 주행 테스트 자동화 — xcodebuildmcp CLI 래퍼
#
# 사용법:
#   scripts/mockride.sh run              # 시뮬레이터 부팅 → 앱 설치 → -UseMockSensors로 실행 (새 세션 시작)
#   scripts/mockride.sh start [투어이름]  # START RECORDING → 이름 입력 alert → 시작
#   scripts/mockride.sh pause            # 일시정지
#   scripts/mockride.sh resume           # 재개
#   scripts/mockride.sh stop             # 트래킹 종료
#   scripts/mockride.sh center           # 현재 위치로 카메라 센터링 (팬 후 팔로우 재개)
#   scripts/mockride.sh shot [라벨]       # 스크린샷을 .mcp-artifacts/<세션>/에 저장
#   scripts/mockride.sh ui               # 현재 화면 UI 스냅샷 (ref 탐색용)
#
# 환경변수: MOCKRIDE_SIM (기본 "iPhone 17 Pro")

set -euo pipefail

SIM_NAME="${MOCKRIDE_SIM:-iPhone 17 Pro}"
BUNDLE_ID="com.woong.MotoTrace"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACTS_ROOT="$ROOT/.mcp-artifacts"
CURRENT_SESSION_FILE="$ARTIFACTS_ROOT/.current-session"
XBM=(npx -y xcodebuildmcp@latest)

# --- 공통 헬퍼 ---

sim_id() {
    xcrun simctl list devices available \
        | grep -m1 -F "$SIM_NAME (" \
        | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'
}

# 세션 디렉터리 — run이 새로 만들고, 나머지 명령은 최근 세션에 이어서 저장
session_dir() {
    if [[ -f "$CURRENT_SESSION_FILE" ]] && [[ -d "$(cat "$CURRENT_SESSION_FILE")" ]]; then
        cat "$CURRENT_SESSION_FILE"
    else
        new_session_dir
    fi
}

new_session_dir() {
    local dir="$ARTIFACTS_ROOT/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$dir"
    echo "$dir" > "$CURRENT_SESSION_FILE"
    echo "$dir"
}

snapshot() {
    "${XBM[@]}" simulator snapshot-ui --simulator-id "$SIM" 2>/dev/null
}

# accessibilityIdentifier(6번 필드) 또는 label(4번 필드)로 elementRef 찾기
# snapshot-ui 라인 형식: "  e21|tap|button|START RECORDING||startRecordingButton"
find_ref() {
    local key="$1"
    snapshot | awk -F'|' -v key="$key" '
        /^  e[0-9]+\|/ {
            gsub(/^ +/, "", $1)
            if ($6 == key || $4 == key) { print $1; exit }
        }'
}

tap_element() {
    local key="$1"
    local ref
    ref=$(find_ref "$key")
    if [[ -z "$ref" ]]; then
        echo "❌ '$key' 요소를 찾지 못했습니다. 'mockride.sh ui'로 화면을 확인하세요." >&2
        exit 1
    fi
    "${XBM[@]}" ui-automation tap --simulator-id "$SIM" --element-ref "$ref" >/dev/null
    echo "✅ tap: $key ($ref)"
}

# --- 서브커맨드 ---

cmd_run() {
    local state
    state=$(xcrun simctl list devices | grep -m1 -F "$SIM_NAME (" | grep -oE '\((Booted|Shutdown)\)' || true)
    if [[ "$state" != "(Booted)" ]]; then
        echo "▶ 시뮬레이터 부팅: $SIM_NAME"
        xcrun simctl boot "$SIM" || true
        xcrun simctl bootstatus "$SIM"
    fi
    open -a Simulator

    local app
    app=$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*MotoTrace-*/Build/Products/Debug-iphonesimulator/MotoTrace.app" -maxdepth 6 2>/dev/null | head -1)
    if [[ -z "$app" ]]; then
        echo "❌ 빌드된 앱을 찾지 못했습니다. 먼저 MotoTrace 스킴을 빌드하세요." >&2
        exit 1
    fi

    echo "▶ 설치: $app"
    "${XBM[@]}" simulator install --simulator-id "$SIM" --app-path "$app" >/dev/null

    local session
    session=$(new_session_dir)
    echo "▶ 실행 (-UseMockSensors), 산출물: $session"
    "${XBM[@]}" simulator launch-app --simulator-id "$SIM" --bundle-id "$BUNDLE_ID" \
        --launch-args "-UseMockSensors" 2>&1 | grep -E "Runtime Logs|OSLog" | tee "$session/launch-logs.txt" || true
    echo "✅ Mock 주행 모드로 실행됨"
}

cmd_start() {
    local tour_name="${1:-}"
    tap_element "startRecordingButton"
    sleep 1

    # 투어 이름 alert: 이름이 주어지면 텍스트 필드에 입력, 아니면 기본 이름("투어 <날짜>") 사용
    # 한글은 HID 키코드로 입력이 안 될 수 있음 — 실패해도 기본 이름으로 계속 진행
    if [[ -n "$tour_name" ]]; then
        local field_ref
        field_ref=$(snapshot | awk -F'|' '/^  e[0-9]+\|/ { gsub(/^ +/,"",$1); if ($3 ~ /text/) { print $1; exit } }')
        if [[ -n "$field_ref" ]] \
            && "${XBM[@]}" ui-automation type-text --simulator-id "$SIM" --element-ref "$field_ref" --text "$tour_name" >/dev/null 2>&1; then
            echo "✅ 투어 이름 입력: $tour_name"
        else
            echo "⚠ 이름 입력 실패(한글 미지원 가능) — 기본 이름으로 진행합니다" >&2
        fi
    fi
    tap_element "시작"
    echo "✅ 트래킹 시작"
}

cmd_shot() {
    local label="${1:-shot}"
    local session
    session=$(session_dir)
    local out
    out=$("${XBM[@]}" simulator screenshot --simulator-id "$SIM" 2>/dev/null | grep -oE '/[^ ]+\.(jpg|png)' | head -1)
    if [[ -z "$out" ]]; then
        echo "❌ 스크린샷 실패" >&2
        exit 1
    fi
    local dest="$session/$(date +%H%M%S)_${label}.jpg"
    cp "$out" "$dest"
    echo "✅ $dest"
}

cmd_ui() {
    snapshot | sed -n '/^Targets/,/^Tips/p' | sed '$d'
}

# --- 엔트리 ---

usage() { sed -n '3,15p' "$0"; exit 1; }

[[ $# -ge 1 ]] || usage
COMMAND="$1"; shift || true

SIM=$(sim_id)
if [[ -z "$SIM" ]]; then
    echo "❌ 시뮬레이터 '$SIM_NAME'을 찾지 못했습니다" >&2
    exit 1
fi

case "$COMMAND" in
    run)    cmd_run ;;
    start)  cmd_start "$@" ;;
    pause)  tap_element "pauseResumeButton" ;;
    resume) tap_element "pauseResumeButton" ;;
    stop)   tap_element "stopButton" ;;
    center) tap_element "currentPositionButton" ;;
    shot)   cmd_shot "$@" ;;
    ui)     cmd_ui ;;
    *)      usage ;;
esac
