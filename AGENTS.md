# MotoTrace

오토바이 라이더용 실시간 라이딩 트래킹 iOS 앱이다. 속도·린앵글·급가속/급감속을 분석하고 경로와 통계를 기록한다. 상세 아키텍처는 README.md에 있다.

## 구조

- `MotoTrace/`: 앱 타깃. 앱 조립은 `MotoTrace/Sources/AppDISetup.swift`
- `Modules/Core/`: CoreSensors, CoreTracking, CoreDataStorage
- `Modules/Feature/`: FeatureTour, FeatureHistory, FeatureSettings, HistoryDetail
- `Modules/DI/AppDI`, `Modules/SharedModules/Shared`
- 모듈 구조와 의존 규칙은 `.claude/rules/project/architecture.md`에 있다. Swift 파일을 읽을 때 함께 로드된다.
- 남은 작업과 발견한 이슈: `docs/BACKLOG.md`

## 프로젝트 규칙

- 새 Feature 모듈은 `make feature name=X`로 만들고, `Tuist/ProjectDescriptionHelpers/ModuleName.swift`에 case를 등록한다.
- 센서·트래킹·지도·통계·히스토리·주행 UI 관련 변경은 `mock-ride` 스킬로 시뮬레이터 가상 주행을 확인한다. 스크린샷은 1~2장만 골라 연다.
- 작업 중 새 이슈를 발견하면 `docs/BACKLOG.md`에 추가한다. "다음 작업" 질문에는 백로그를 기준으로 답한다.
- 기능·버그 작업은 `feature/<주제>`, `fix/<주제>` 브랜치(영문 kebab-case)에서 한다. 문서·설정 한두 파일 수준의 `docs:`/`chore:` 커밋은 main에 직접 해도 된다.
- PR 전에는 `scripts/harness/verify --base main`, `ios-reviewer` 리뷰, `/codex:review --wait --base main`을 모두 거친다. 리뷰에서 나온 항목을 처리(수정 또는 오탐 판단)하고, 검증 결과와 리뷰 결과(발견 건수, 처리 내역)를 PR 본문에 적는다. 수정이 생기면 다시 검증하고 리뷰한다.
- 머지는 squash merge로 하고, 머지한 뒤 브랜치를 지운다.
- 커밋 메시지는 한글로 쓰고, prefix는 `feat:` `fix:` `docs:` `test:` `chore:` 중 하나를 쓴다.
- 규모 있는 작업은 플랜 모드로 계획을 먼저 승인받은 뒤 구현한다.
- 병렬 세션은 워크트리 슬롯으로 나눈다. 슬롯 하나에는 세션 하나만 붙이고, 여러 슬롯에서 동시에 빌드·시뮬레이터 테스트를 돌리지 않는다.
  - `MotoTrace/`: main 전용 (체크아웃 변경 금지)
  - `MotoTrace-feature/`: feature/* · `MotoTrace-fix/`: fix/* · `MotoTrace-ai-workflow/`: AI 워크플로
  - 작업이 없는 슬롯은 main 시점의 detached HEAD로 둔다. 슬롯 현황은 `git worktree list`로 본다.

<!-- harness:begin — 이 아래는 하네스가 관리한다. 고칠 내용은 하네스 저장소의 template/AGENTS.md에 반영한다. -->

## 빌드·테스트

| 할 일 | 명령 |
|---|---|
| 코드를 바꾼 뒤 검증 (앱 빌드 + 바뀐 모듈 테스트) | `scripts/harness/verify` |
| 무엇을 돌릴지 미리 보기 | `scripts/harness/verify --plan` |
| PR 전에 브랜치 전체 변경 검증 | `scripts/harness/verify --base <기본 브랜치>` |
| 빌드만 | `scripts/harness/build` |
| 앱 단위 테스트 / 특정 스킴 테스트 | `scripts/harness/test` / `scripts/harness/test --scheme <스킴>` |

- 스킴, 시뮬레이터, 프로젝트 생성 명령은 `.harness/project.json`에 있고 스크립트가 이 파일을 읽는다. `xcodebuild`를 직접 구성하지 않는다.
- 실패하면 출력에 나온 첫 에러의 위치부터 고친다. 전체 로그와 결과 번들은 `.harness/out/`에 있다.
- 결과는 실제로 실행한 명령과 출력으로 보고한다. 실행하지 못한 검증은 못 했다고 밝힌다.
- PR을 만들기 전에는 `ios-reviewer` 서브에이전트(ios-harness 플러그인)에 변경 검토를 맡기고, 차단 항목을 고친 뒤 올린다.

## 꼭 지킬 규칙

위의 프로젝트 규칙이 아래와 다르면 프로젝트 규칙을 따른다.

- 기존 아키텍처와 패턴을 우선 존중한다. 요청받지 않은 대규모 refactor는 하지 않고, 변경 범위를 작게 유지한다.
- 검증을 통과시키려고 설정을 완화하거나 테스트를 약화하지 않는다.
- 커밋, push, PR 생성·머지는 사용자가 요청하거나 승인한 뒤에 한다. 커밋 전에는 메시지와 대상 파일을 먼저 보여준다.
- 사용자가 명시적으로 요청하지 않으면 파괴적인 git 명령을 쓰지 않는다: `push --force`, `reset --hard`, `clean -fd`, `checkout -- .` / `restore .`, `branch -D`, 이미 push된 브랜치의 rebase.
- `--no-verify` 등으로 훅을 우회하지 않는다. 훅이 막으면 원인을 해결한다.
- 파일을 지정해 스테이징한다. 비밀 정보(API 키, 인증서, 프로비저닝 프로파일, `.env`)와 생성 산출물은 커밋하지 않는다.
- 커밋 메시지와 브랜치 이름은 프로젝트의 기존 관례를 따른다. 모르면 `git log`로 확인한다.
- 충돌을 해결할 때 상대 쪽 변경을 임의로 버리지 않는다. 의도가 불분명하면 확인한다.

## 상황별 규칙

Claude Code는 아래 규칙을 해당 파일을 읽을 때 자동으로 불러온다. 다른 에이전트는 작업 전에 해당하는 규칙 파일을 읽는다.

| 다루는 파일 | 규칙 |
|---|---|
| Swift 코드 | `.claude/rules/harness/swift.md`, `swiftui.md`, `concurrency.md`, `dependencies.md` |
| 테스트 코드, 테스트 플랜 | `.claude/rules/harness/testing.md` |
| 프로젝트 파일·빌드 설정(pbxproj, xcconfig, entitlements, Info.plist, manifest) | `.claude/rules/harness/project-settings.md` |
| Tuist manifest(`Project.swift`, `Workspace.swift`, `Tuist/`) | `.claude/rules/harness/tuist.md` |
| 이 프로젝트에만 있는 규칙 | `.claude/rules/project/` |

<!-- harness:end -->
