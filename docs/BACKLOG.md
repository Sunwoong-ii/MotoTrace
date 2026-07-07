# Backlog

작업 우선순위 창고. 새 할 일이 생기면 여기에 추가하고, 작업 시작 시 위에서부터 꺼낸다.
완료한 항목은 체크 후 다음 정리 때 삭제한다.

## 우선순위 높음

- [ ] 깨진 LeanAngleAnalyzer 테스트 2건 수정 — `f7320c1`에서 린앵글 계산이 gravity 벡터 방식으로 바뀌었는데 테스트 픽스처가 rollDegrees만 설정해서 실패 중 (`Modules/Core/CoreTracking/Tests/Sources/LeanAngleAnalyzerTests.swift` L109, L136)
- [ ] TourStore 단위 테스트 작성 — pause/resume/stop/restore 상태머신 검증 (mock sensors/repository 필요)

## AI 워크플로 고도화

- [ ] 스캐폴딩 스킬화 — `make feature name=X` 후 수동으로 하던 ModuleName.swift case 등록까지 자동화하는 스킬(`.claude/skills/`) 작성
- [ ] 브랜치/PR 기반 git 워크플로 정착 — main 직접 커밋 대신 작업 브랜치 + PR (gh CLI 인증 완료 상태)

## 발견된 이슈 (조사 필요)

- [ ] 세션 복구 시 analyzer가 새 인스턴스라 이전 주행 거리/통계가 0부터 시작 → `updateStats()`가 저장된 값을 더 작은 값으로 덮어쓰는 문제
- [ ] Tuist manifest에 FeatureTour → CoreDataStorageInterface 의존성 누락 (빌드 경고 발생 중)
- [ ] `updateStats()`가 매초 repository에 쓰기 — README의 "30회 업데이트마다 저장"과 불일치 여부 확인
- [ ] FeatureSettings 개발 — TrackingPolicy 임계값(급가속/뱅킹각/정차 기준)을 설정 화면과 연결
