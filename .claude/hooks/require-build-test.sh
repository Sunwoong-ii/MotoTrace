#!/bin/bash
# 커밋 게이트 (PreToolUse 훅) — git commit 실행 전에 빌드+변경 모듈 테스트를 강제한다.
# 실패 시 permissionDecision=deny 로 커밋 자체를 차단한다.
set -u

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git commit 이 포함된 명령만 게이트 대상 (matcher 는 Bash 전체라 여기서 걸러야 한다)
case "$COMMAND" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

# 디렉터리 진입 실패 시 게이트를 건너뛰면(fail-open) 검증 없이 커밋되므로 반드시 차단한다
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // "."')}"
cd "$PROJECT_DIR" || deny "커밋 게이트: 프로젝트 디렉터리($PROJECT_DIR) 진입 실패 — 검증 불가로 커밋을 차단합니다."

# 변경 파일 수집: "git add X && git commit" 복합 명령은 훅 시점에 아직 스테이징 전이므로
# 스테이징·미스테이징·미추적을 모두 본다
CHANGED=$( (git diff --cached --name-only; git diff --name-only; git ls-files --others --exclude-standard) | sort -u )

# 소스에 영향 없는 변경(문서·스크립트 등)은 게이트 생략
if ! printf '%s\n' "$CHANGED" | grep -qE '\.swift$|\.xcconfig$|^Tuist/'; then
  exit 0
fi

DEST="platform=iOS Simulator,name=${COMMIT_GATE_SIM:-iPhone 17 Pro}"
LOG=$(mktemp -t commit-gate)

# 모듈 테스트는 앱 타겟을 빌드하지 않으므로, 앱 타겟 컴파일 깨짐은 이 빌드만 잡는다 (중복 아님)
echo "커밋 게이트: 앱 빌드 검증 중..." >&2
if ! xcodebuild -workspace MotoTrace.xcworkspace -scheme MotoTrace \
     -destination "$DEST" build >"$LOG" 2>&1; then
  deny "커밋 게이트: 빌드 실패로 커밋을 차단했습니다. $(grep -E 'error:' "$LOG" | head -5 | tr '\n' ' ') (전체 로그: $LOG)"
fi

# 변경 파일에서 모듈명 추출 → Tests 타겟이 있는 모듈만 테스트
SCHEMES=$(printf '%s\n' "$CHANGED" | sed -nE 's#^Modules/[^/]+/([^/]+)/.*#\1#p' | sort -u)
for SCHEME in $SCHEMES; do
  TESTS_DIR=$(ls -d Modules/*/"$SCHEME"/Tests 2>/dev/null | head -1)
  [ -z "$TESTS_DIR" ] && continue
  echo "커밋 게이트: $SCHEME 테스트 실행 중..." >&2
  if ! xcodebuild -workspace MotoTrace.xcworkspace -scheme "$SCHEME" \
       -destination "$DEST" test >"$LOG" 2>&1; then
    deny "커밋 게이트: $SCHEME 테스트 실패로 커밋을 차단했습니다. $(grep -E 'Test Case.*failed|error:' "$LOG" | head -5 | tr '\n' ' ') (전체 로그: $LOG)"
  fi
done

# 성공 시 로그 정리 (실패 시에는 디버깅용으로 deny 사유에 경로를 남기고 보존)
rm -f "$LOG"
exit 0
