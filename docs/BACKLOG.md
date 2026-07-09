# Backlog

작업 우선순위 창고. 새 할 일이 생기면 여기에 추가하고, 작업 시작 시 위에서부터 꺼낸다.
완료한 항목은 체크 후 다음 정리 때 삭제한다.

## 우선순위 높음

- [x] Mock 센서 구현 — 라이딩 없이 트래킹 전체 플로우를 검증할 수 있도록 `-UseMockSensors` launch argument로 가상 주행 데이터(급가속·급감속·뱅킹각 이벤트 포함 시나리오)를 방출하는 `CoreSensorsInterface` 구현체 추가. `MotoTrace-MockRide` 스킴으로 실행 (시뮬레이터에서 트래킹·일시정지·재개·종료·히스토리 저장 검증 완료)
- [x] Mock 모드 지도 카메라 팔로우 — Mock 트래킹 중 카메라가 가상 경로 끝을 따라가고 커스텀 현재위치 마커 표시 (실 GPS의 `.userLocation` 팔로우는 변경 없음, `LaunchFlags.useMockSensors` 분기)
- [x] Mock 주행 테스트 자동화 — `scripts/mockride.sh`(run/start/pause/resume/stop/shot/ui) + `.claude/skills/mock-ride` 스킬 + `.mcp-artifacts/` 산출물 디렉터리, 주요 버튼에 accessibilityIdentifier 부여
- [x] 앱 시작 시 위치 권한 요청 — RootTabView `.task`에서 When-In-Use 선요청, 트래킹 시작 시 Always 승격은 기존 유지 (2단계 전략)
- [ ] 위치 권한 거부 상태 처리 — `CoreSensorsInterface`에 권한 상태 조회(authorizationStatus) 추가하고, 거부/제한 시 설정 앱 유도 UI 표시
- [ ] 백그라운드에서 위치·린앵글 수집 정상 여부 검증 — 실기기 백그라운드 상태에서 location/motion 스트림이 끊기지 않고 수집되는지 확인 (CMMotionManager는 백그라운드 제약 있음 — 위치 백그라운드 모드만으로 motion 콜백이 유지되는지가 핵심)
- [ ] 백그라운드 메모리·배터리 사용량 측정 — 장시간 트래킹 시 Instruments(Allocations/Energy Log) 또는 MetricKit으로 프로파일링, 위치 정확도/모션 주기 튜닝 근거 마련
- [x] 깨진 LeanAngleAnalyzer 테스트 2건 수정 — 실제 원인은 좌표계 불일치: 구현은 CMDeviceMotion xTrueNorthZVertical(NWU)인데 테스트 픽스처가 ENU 가정으로 작성됨. 픽스처를 NWU로 수정, 무의미하게 통과하던 좌우 부호 테스트도 실질 검증하도록 보강
- [ ] TourStore 단위 테스트 작성 — pause/resume/stop/restore 상태머신 검증 (mock sensors/repository 필요)

## AI 워크플로 고도화

- [ ] 스캐폴딩 스킬화 — `make feature name=X` 후 수동으로 하던 ModuleName.swift case 등록까지 자동화하는 스킬(`.claude/skills/`) 작성
- [x] 브랜치/PR 기반 git 워크플로 정착 — CLAUDE.md 워크플로 규칙에 반영 (feature/fix 브랜치 → PR(검증 결과 포함) → squash merge, 소규모 docs/chore는 main 직접 허용)
- [ ] 커스텀 스킬 추가 확충 — mock-ride·스캐폴딩 외에 반복 워크플로 스킬화. 후보: ① 빌드+관련 모듈 테스트+시뮬레이터 확인까지 한 번에 도는 검증 스킬, ② PR 생성 스킬(브랜치 규칙·본문 템플릿·검증 결과 자동 포함), ③ MVI Store 테스트 보일러플레이트 생성 스킬
- [ ] GitHub MCP 도입 검토 — 현행 gh CLI 방식과 비교해 장단점(토큰 관리, 컨텍스트 비용, PR 리뷰 코멘트 접근성 등) 정리 후 도입 여부 결정. 도입 시 `.mcp.json`에 등록
- [x] 검증 분리 — ① 커밋 게이트 훅: `.claude/hooks/require-build-test.sh` + `.claude/settings.json` PreToolUse 훅으로 git commit 전 앱 빌드+변경 모듈 테스트 강제, ② 로컬 리뷰: CLAUDE.md에 "PR 생성 전 /code-review" 규칙 추가 (커스텀 리뷰 에이전트는 내장 /code-review로 충분한지 써본 뒤 판단)

## 발견된 이슈 (조사 필요)

- [ ] 세션 복구 시 analyzer가 새 인스턴스라 이전 주행 거리/통계가 0부터 시작 → `updateStats()`가 저장된 값을 더 작은 값으로 덮어쓰는 문제
- [ ] Tuist manifest에 FeatureTour → CoreDataStorageInterface 의존성 누락 (빌드 경고 발생 중)
- [ ] `updateStats()`가 매초 repository에 쓰기 — README의 "30회 업데이트마다 저장"과 불일치 여부 확인
- [ ] FeatureSettings 개발 — TrackingPolicy 임계값(급가속/뱅킹각/정차 기준)을 설정 화면과 연결
