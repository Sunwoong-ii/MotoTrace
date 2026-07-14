#!/bin/bash
# 커밋 게이트 (PreToolUse 훅) — git commit 전에 검증 스탬프(scripts/verify-stamp.sh)가
# 현재 작업 트리와 일치하는지 확인한다. 빌드+테스트는 Codex 위임 검증이 수행하고,
# 성공 시 스탬프를 남긴다 — 훅은 "검증된 그대로의 트리인지"만 수 초 안에 검사한다.
# 스탬프 없음/불일치 시 permissionDecision=deny 로 커밋을 차단한다.
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

# 스탬프 스크립트가 없으면 검증 자체가 불가능하므로 차단 (fail-closed)
[ -x "scripts/verify-stamp.sh" ] || deny "커밋 게이트: scripts/verify-stamp.sh 가 없거나 실행 불가 — 검증 불가로 커밋을 차단합니다."

# 스탬프 검사 — Codex 검증(빌드+변경 모듈 테스트) 성공 시점의 트리 지문과 대조
RESULT=$(scripts/verify-stamp.sh check 2>&1)
if [ $? -ne 0 ]; then
  deny "커밋 게이트: $RESULT Codex에 빌드+테스트 검증을 위임하고, 성공 후 'scripts/verify-stamp.sh write \"<검증 증거 요약>\"'으로 스탬프를 남긴 뒤 다시 커밋하세요."
fi

exit 0
