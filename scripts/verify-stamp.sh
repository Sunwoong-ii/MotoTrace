#!/usr/bin/env bash
#
# 검증 스탬프 — 빌드+테스트 검증(Codex 위임 또는 직접)이 성공한 시점의 트리 지문과
# 검증 증거를 기록하고, 커밋 게이트가 현재 지문과 대조한다.
# "검증 이후 빌드 영향 변경이 생기면 무효"라는 규칙을 관례가 아니라 기계적 검사로 보장한다.
#
# 사용법:
#   scripts/verify-stamp.sh write [검증 증거 요약]  # 검증 성공 직후 — 지문+증거 기록
#   scripts/verify-stamp.sh check                   # 지문 일치 여부 (exit 0=유효, 1=없음/불일치)
#   scripts/verify-stamp.sh show                    # 스탬프 상태 출력 (디버깅용)
#
# 지문 구성: HEAD 커밋 + 빌드 영향 파일(.swift/.xcconfig/Tuist/)의 diff·미추적 내용 해시.
# 문서·스크립트만 바꾸는 변경은 지문을 바꾸지 않는다 — 커밋 게이트의 생략 조건과 같은 기준이라,
# 검증 후 README 수정 같은 무해한 변경으로 스탬프가 무효화되는 과잉 반응을 막는다.
# 워크트리별로 독립 — 스탬프는 해당 워크트리의 .mcp-artifacts/(gitignore 대상)에 저장된다.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
STAMP="$ROOT/.mcp-artifacts/verify-stamp"
# 커밋 게이트(.claude/hooks/require-build-test.sh)의 게이트 대상 패턴과 반드시 같게 유지한다
BUILD_PATTERN='\.swift$|\.xcconfig$|^Tuist/'

fingerprint() {
    {
        git -C "$ROOT" rev-parse HEAD
        git -C "$ROOT" diff HEAD -- '*.swift' '*.xcconfig' 'Tuist/'
        # 미추적 파일은 diff에 안 잡히므로 경로+내용 해시를 별도로 포함한다
        git -C "$ROOT" ls-files --others --exclude-standard \
            | { grep -E "$BUILD_PATTERN" || true; } | LC_ALL=C sort \
            | while IFS= read -r f; do
                printf '%s %s\n' "$f" "$(git -C "$ROOT" hash-object -- "$ROOT/$f" 2>/dev/null || echo gone)"
            done
    } | shasum -a 256 | awk '{print $1}'
}

case "${1:-}" in
    write)
        shift
        mkdir -p "$(dirname "$STAMP")"
        {
            fingerprint
            date '+%Y-%m-%d %H:%M:%S'
            # 3행부터: 검증 증거(빌드/테스트 결과 요약) — 게이트 통과 근거의 감사 기록
            if [ $# -gt 0 ]; then printf '%s\n' "$*"; fi
        } > "$STAMP"
        echo "검증 스탬프 기록 완료: $STAMP"
        ;;
    check)
        if [[ ! -f "$STAMP" ]]; then
            echo "검증 스탬프 없음 — 빌드+테스트 검증 후 'scripts/verify-stamp.sh write \"<검증 증거 요약>\"'을 실행하세요."
            exit 1
        fi
        if [[ "$(head -1 "$STAMP")" != "$(fingerprint)" ]]; then
            echo "검증 스탬프 불일치 — 검증($(sed -n 2p "$STAMP")) 이후 빌드 영향 파일이 변경됐습니다. 재검증이 필요합니다."
            exit 1
        fi
        EVIDENCE=$(sed -n '3,$p' "$STAMP")
        echo "검증 스탬프 유효 (검증 시각: $(sed -n 2p "$STAMP")${EVIDENCE:+ · $EVIDENCE})"
        ;;
    show)
        echo "현재 지문: $(fingerprint)"
        if [[ -f "$STAMP" ]]; then
            echo "스탬프 지문: $(head -1 "$STAMP") (기록 시각: $(sed -n 2p "$STAMP"))"
            EVIDENCE=$(sed -n '3,$p' "$STAMP")
            if [[ -n "$EVIDENCE" ]]; then echo "검증 증거: $EVIDENCE"; fi
        else
            echo "스탬프 없음: $STAMP"
        fi
        ;;
    *)
        echo "사용법: $0 {write [검증 증거 요약]|check|show}" >&2
        exit 2
        ;;
esac
