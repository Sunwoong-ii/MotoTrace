# MotoTrace

오토바이 라이더용 실시간 라이딩 트래킹 iOS 앱. 속도·린앵글·급가속/급감속을 분석하고 경로와 통계를 기록한다. 상세 아키텍처는 README.md 참고.

## 필수 명령어

```bash
make generate        # tuist generate — 워크스페이스 생성 (파일 추가/삭제 후 필수)
make clean           # tuist clean 후 재생성
make feature name=X  # Feature 모듈 스캐폴딩 (생성 후 ModuleName.swift에 case 등록 필수)
```

빌드/테스트 **검증은 Codex 위임이 기본**이다 (워크플로 규칙의 검증 루프 참고, Codex 쪽 지침은 AGENTS.md). Claude가 직접 확인할 일이 있으면 XcodeBuildMCP 도구를 우선 사용. 없으면:

```bash
xcodebuild -workspace MotoTrace.xcworkspace -scheme MotoTrace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -workspace MotoTrace.xcworkspace -scheme <모듈명> \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Tuist 주의사항

- `.xcodeproj` / `.xcworkspace` / `Derived/`는 **gitignore 대상** — 절대 커밋하지 않는다
- 소스 파일을 추가·삭제·이동하면 반드시 `make generate`로 재생성 후 빌드
- 프로젝트 설정 변경은 Xcode가 아니라 각 모듈의 `Project.swift` / `Tuist/` manifest에서 한다

## 아키텍처 규칙

- **모듈 구조**: 각 모듈은 `Interface` / `Implementation` / `Tests` (+ Feature는 `Demo`) 타겟으로 분리
- **의존 방향**: Feature와 앱 타겟은 다른 모듈의 **Interface에만 의존**한다. Implementation을 직접 import하는 코드는 금지
- **DI**: 외부 라이브러리 없이 자체 `AppDIContainer` 사용. 구현체 등록은 각 모듈의 `*Assembly.swift`, 앱 조립은 `MotoTrace/Sources/AppDISetup.swift`
- **MVI 패턴**: Feature는 `State`(값 타입) / `Intent`(enum) / `Store`(`@MainActor ObservableObject`, `send(_:)` 단일 진입점)로 구성. FeatureTour가 표준 예시
- 새 모듈 생성 시 `ModuleName.swift`에 case 등록을 잊지 말 것

## 코드 컨벤션

- Swift 6, Swift Concurrency 사용 (async/await, AsyncStream). 센서 데이터는 AsyncStream으로 스트리밍
- 주석은 한글. "왜"를 설명하는 주석만 작성
- 테스트는 XCTest + GWT(Given-When-Then), 테스트명은 한글 (`test_동작_조건_기대결과` 형식)

## 워크플로 규칙

- **백로그**: 남은 작업과 발견된 이슈는 `docs/BACKLOG.md`에서 관리한다. 작업 중 새 이슈를 발견하면 백로그에 추가하고, "다음 작업" 질문에는 백로그 기준으로 답한다
- **브랜치/PR 워크플로**: 기능·버그 단위 작업은 main 직접 커밋 대신 브랜치에서 작업한다
  - 브랜치 이름: `feature/<주제>`, `fix/<주제>` (영문 kebab-case)
  - 작업 완료 후 gh CLI로 PR 생성 — PR 본문에 변경 요약과 검증 결과(빌드/테스트/시뮬레이터 확인)를 포함한다
  - **PR 생성 전 `/codex:review --wait --base main` 실행**: 발견 사항을 처리(수정 또는 오탐 판단)한 뒤, 리뷰 결과 요약(발견 건수·처리 내역)을 PR 본문 검증 섹션에 포함한다. 수정이 생기면 재검증(스탬프 갱신) 후 리뷰를 다시 돌린다 (`--wait` 고정 — 실행 방식 질문 생략)
  - 머지는 squash merge, 머지 후 브랜치 삭제
  - **예외**: 문서·설정 한두 파일 수준의 `docs:`/`chore:` 커밋은 main 직접 커밋 허용
  - PR 생성·머지도 커밋과 동일하게 사전 확인 규칙을 적용한다 (명시적 승인 후 실행)
- **병렬 세션은 워크트리 슬롯으로 분리**: 용도별 고정 워크트리에서 작업하고, 한 슬롯에는 세션 하나만 붙는다 — 미커밋 변경이 브랜치 전환에 딸려가는 사고 방지
  - 슬롯 구성: `MotoTrace/`=main 전용(체크아웃 변경 금지, pull·소규모 docs 커밋용), `MotoTrace-feature/`=feature/* 슬롯, `MotoTrace-fix/`=fix/* 슬롯, `MotoTrace-ai-workflow/`=AI 워크플로 슬롯
  - 슬롯은 한 번에 한 브랜치를 체크아웃한다. 작업 없는 슬롯은 detached HEAD(main 시점)로 대기
  - 현재 위치·슬롯 현황 확인은 `git worktree list`. 새 슬롯을 만들면 `make generate` 필요 (`.xcworkspace`는 gitignore 대상이라 워크트리에 없음)
  - 여러 슬롯에서 동시에 빌드/시뮬레이터 테스트를 돌리지 않는다 (시뮬레이터·CPU 경합)
- **계획–실행 분리**: 규모 있는 작업은 플랜 모드로 계획을 먼저 승인받은 뒤 구현한다
- **커밋은 반드시 사전 확인**: `git add`/`git commit` 전에 커밋 메시지와 대상 파일을 보여주고 명시적 승인을 받는다. 계획에 커밋이 포함돼 있었어도 예외 없음
- **커밋 컨벤션**: 한글 메시지, prefix는 `feat:` `fix:` `docs:` `test:` `chore:`
- **검증 루프 (Codex 위임)**: Swift/Tuist 변경 후 커밋 전에 Codex에 빌드+테스트 검증을 위임한다
  - 위임 방법: `codex:codex-rescue` 서브에이전트 사용, **read-only 강제**(`--write` 금지). 프롬프트에 "XcodeBuildMCP MCP 도구로 앱 빌드 + 변경 모듈 테스트 실행, 소스 수정 금지, 결과만 보고"를 명시한다 (셸 xcodebuild는 read-only 샌드박스에 막히므로 MCP 도구 필수 — 상세는 AGENTS.md)
  - 성공 보고를 받으면 **Claude가 `scripts/verify-stamp.sh write "빌드: 성공 / <모듈>: N/N 통과"` 형식으로 검증 증거와 함께 스탬프를 기록**한다. 반드시 성공 보고를 받은 뒤에만 기록한다. 실패·미검증 상태에서는 커밋하지 않는다
  - 스탬프 지문은 빌드 영향 파일(`.swift`/`.xcconfig`/`Tuist/`) 기준 — 검증 후 빌드 영향 파일이 바뀌면 자동 무효화되므로 재검증한다 (문서·스크립트 변경은 무효화하지 않음)
  - **Codex 사용 불가 시 fallback**: 로그인 만료·장애 등으로 위임이 안 되면 Claude가 직접 XcodeBuildMCP로 빌드+변경 모듈 테스트를 수행하고 같은 방식으로 스탬프를 기록한다
  - 센서·트래킹·지도·통계·히스토리·주행 UI 관련 변경은 **mock ride 검증을 Claude가 직접** `scripts/mockride.sh`로 실행한다 (Codex 위임 불가 — Codex 샌드박스가 CoreSimulatorService XPC를 차단해 시뮬레이터 셸 제어가 안 됨, 리허설로 실측 확인). 스크린샷은 1~2장만 선별해 열람한다
- **커밋 게이트 훅 (스탬프 검사)**: `git commit` 시 PreToolUse 훅(`.claude/hooks/require-build-test.sh`)이 검증 스탬프(`scripts/verify-stamp.sh check`)와 현재 작업 트리의 일치 여부를 확인하고, 없거나 불일치하면 커밋을 차단한다 (Swift/Tuist 변경이 없으면 생략). 빌드+테스트를 직접 돌리지 않으므로 수 초 안에 끝난다
