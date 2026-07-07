# MotoTrace

오토바이 라이더용 실시간 라이딩 트래킹 iOS 앱. 속도·린앵글·급가속/급감속을 분석하고 경로와 통계를 기록한다. 상세 아키텍처는 README.md 참고.

## 필수 명령어

```bash
make generate        # tuist generate — 워크스페이스 생성 (파일 추가/삭제 후 필수)
make clean           # tuist clean 후 재생성
make feature name=X  # Feature 모듈 스캐폴딩 (생성 후 ModuleName.swift에 case 등록 필수)
```

빌드/테스트는 XcodeBuildMCP 도구를 우선 사용. 없으면:

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

- **계획–실행 분리**: 규모 있는 작업은 플랜 모드로 계획을 먼저 승인받은 뒤 구현한다
- **커밋은 반드시 사전 확인**: `git add`/`git commit` 전에 커밋 메시지와 대상 파일을 보여주고 명시적 승인을 받는다. 계획에 커밋이 포함돼 있었어도 예외 없음
- **커밋 컨벤션**: 한글 메시지, prefix는 `feat:` `fix:` `docs:` `test:` `chore:`
- **검증 루프**: 코드 수정 후 빌드 → 관련 모듈 테스트 → (UI 변경 시) 시뮬레이터 실행 확인까지 마친 뒤 완료 보고
