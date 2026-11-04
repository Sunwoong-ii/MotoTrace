---
paths:
  - "**/*.swift"
---

# MotoTrace 아키텍처

- 모듈은 `Interface` / `Implementation` / `Tests` 타깃으로 나눈다. Feature 모듈에는 `Demo` 타깃도 있다.
- Feature와 앱 타깃은 다른 모듈의 Interface에만 의존한다. Implementation 모듈을 직접 import하지 않는다.
- DI는 외부 라이브러리 없이 자체 `AppDIContainer`를 쓴다. 구현체 등록은 각 모듈의 `*Assembly.swift`에서, 앱 조립은 `MotoTrace/Sources/AppDISetup.swift`에서 한다.
- Feature는 MVI로 구성한다: `State`(값 타입) / `Intent`(enum) / `Store`(`@MainActor ObservableObject`, `send(_:)` 단일 진입점). FeatureTour가 표준 예시다.
- Swift 6과 Swift Concurrency(async/await, AsyncStream)를 쓴다. 센서 데이터는 AsyncStream으로 흘려보낸다.
- 주석은 한글로 쓰고, "왜"를 설명하는 주석만 남긴다.
