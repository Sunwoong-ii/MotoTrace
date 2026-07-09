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

# 세션 cwd를 우선한다 — 워크트리 세션에서 CLAUDE_PROJECT_DIR은 본 체크아웃을
# 가리키므로, 그걸 쓰면 다른 워크트리(다른 세션의 작업물)를 검증하게 된다
PROJECT_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
fi
# 디렉터리 진입 실패 시 게이트를 건너뛰면(fail-open) 검증 없이 커밋되므로 반드시 차단한다
cd "$PROJECT_DIR" || deny "커밋 게이트: 프로젝트 디렉터리($PROJECT_DIR) 진입 실패 — 검증 불가로 커밋을 차단합니다."

# 변경 파일 수집: "git add X && git commit" 복합 명령은 훅 시점에 아직 스테이징 전이므로
# 스테이징·미스테이징·미추적을 모두 본다
CHANGED=$( (git diff --cached --name-only; git diff --name-only; git ls-files --others --exclude-standard) | sort -u )

# 소스에 영향 없는 변경(문서·스크립트 등)은 게이트 생략
if ! printf '%s\n' "$CHANGED" | grep -qE '\.swift$|\.xcconfig$|^Tuist/'; then
  exit 0
fi

DEST="platform=iOS Simulator,name=${COMMIT_GATE_SIM:-iPhone 17 Pro}"

# 게이트 로그는 .mcp-artifacts/commit-gate/에 실행(RUN_ID) 단위로 보존한다
# — 성공 로그도 남겨 빌드 시간 추이 등을 추적할 수 있게 하고, 최근 20회분만 유지
LOG_DIR=".mcp-artifacts/commit-gate"
mkdir -p "$LOG_DIR"
RUN_ID=$(date +%Y%m%d-%H%M%S)
# .DS_Store 등 비패턴 파일이 섞이면 보존 회수 계산이 어긋나므로 타임스탬프 형식만 센다
ls -1 "$LOG_DIR" | grep -E '^[0-9]{8}-[0-9]{6}_' | cut -d_ -f1 | sort -ur | sed -n '21,$p' | while read -r old; do
  rm -f "$LOG_DIR/${old}"_*
done

# 모듈 테스트는 앱 타겟을 빌드하지 않으므로, 앱 타겟 컴파일 깨짐은 이 빌드만 잡는다 (중복 아님)
BUILD_LOG="$LOG_DIR/${RUN_ID}_build.log"
echo "커밋 게이트: 앱 빌드 검증 중..." >&2
if ! xcodebuild -workspace MotoTrace.xcworkspace -scheme MotoTrace \
     -destination "$DEST" build >"$BUILD_LOG" 2>&1; then
  deny "커밋 게이트: 빌드 실패로 커밋을 차단했습니다. $(grep -E 'error:' "$BUILD_LOG" | head -5 | tr '\n' ' ') (전체 로그: $BUILD_LOG)"
fi

# 변경 파일에서 모듈명 추출 → Tests 타겟이 있는 모듈만 테스트
SCHEMES=$(printf '%s\n' "$CHANGED" | sed -nE 's#^Modules/[^/]+/([^/]+)/.*#\1#p' | sort -u)
for SCHEME in $SCHEMES; do
  TESTS_DIR=$(ls -d Modules/*/"$SCHEME"/Tests 2>/dev/null | head -1)
  [ -z "$TESTS_DIR" ] && continue
  TEST_LOG="$LOG_DIR/${RUN_ID}_${SCHEME}-test.log"
  echo "커밋 게이트: $SCHEME 테스트 실행 중..." >&2
  if ! xcodebuild -workspace MotoTrace.xcworkspace -scheme "$SCHEME" \
       -destination "$DEST" test >"$TEST_LOG" 2>&1; then
    deny "커밋 게이트: $SCHEME 테스트 실패로 커밋을 차단했습니다. $(grep -E 'Test Case.*failed|error:' "$TEST_LOG" | head -5 | tr '\n' ' ') (전체 로그: $TEST_LOG)"
  fi
done

exit 0
