# MotoTrace — Codex 작업 지침

아키텍처·모듈 구조·코드 컨벤션·필수 명령어는 **CLAUDE.md를 그대로 따른다**. 이 문서는 Codex에 위임되는 작업의 역할과 실행 방법만 정의한다.

## 역할

Codex는 이 저장소에서 **검증자**다. Claude Code가 소스 작성·git·작업 조율·mock ride(시뮬레이터 가상 주행)를 담당하고, Codex는 다음을 위임받는다:

1. **빌드+테스트 검증** (read-only)
2. **PR 전 코드 리뷰** (`/codex:review`, 플러그인 경유)

mock ride는 위임 대상이 아니다 — Codex 샌드박스가 CoreSimulatorService XPC를 차단해 `scripts/mockride.sh`(셸 기반 시뮬레이터 제어)가 실행되지 않는다. XcodeBuildMCP **MCP 도구**는 샌드박스 밖 프로세스라 정상 동작하므로 빌드/테스트에는 문제가 없다.

## 공통 규칙

- **소스 코드를 수정하지 않는다.** 검증 태스크에서 발견한 문제는 수정하지 말고 보고만 한다
- 시뮬레이터 기본값: `iPhone 17 Pro`, 워크스페이스 `MotoTrace.xcworkspace`
- 다른 워크트리에서 빌드가 돌고 있을 수 있으므로, 위임받은 작업 외의 빌드를 추가로 돌리지 않는다

## 빌드+테스트 검증 (read-only 샌드박스)

**반드시 XcodeBuildMCP MCP 도구를 사용한다** — 셸에서 `xcodebuild`를 직접 실행하면 DerivedData 쓰기가 read-only 샌드박스에 막혀 실패한다. MCP 서버 프로세스는 샌드박스 밖에서 실행되므로 정상 동작한다.

절차:
1. `build_sim` — 워크스페이스 `MotoTrace.xcworkspace`, 스킴 `MotoTrace`로 앱 빌드
2. 변경된 모듈마다 (경로 `Modules/*/<모듈명>/`에 `Tests/` 타겟이 있는 경우) `test_sim` — 스킴 `<모듈명>`으로 테스트
3. 결과 보고: 빌드 성공 여부, 모듈별 테스트 통과/실패 수, 실패 시 오류 요약

검증 스탬프(`scripts/verify-stamp.sh write`)는 Codex가 아니라 **Claude가 성공 보고를 받은 뒤 기록**한다 — read-only 위임에서는 파일을 쓸 수 없고, 그래야 하는 게 맞다.
