# Backlog

작업 우선순위 창고. 새 할 일이 생기면 여기에 추가하고, 작업 시작 시 위에서부터 꺼낸다.
완료한 항목은 체크 후 다음 정리 때 삭제한다.

## 우선순위 높음

- [x] Mock 센서 구현 — 라이딩 없이 트래킹 전체 플로우를 검증할 수 있도록 `-UseMockSensors` launch argument로 가상 주행 데이터(급가속·급감속·뱅킹각 이벤트 포함 시나리오)를 방출하는 `CoreSensorsInterface` 구현체 추가. `MotoTrace-MockRide` 스킴으로 실행 (시뮬레이터에서 트래킹·일시정지·재개·종료·히스토리 저장 검증 완료)
- [x] Mock 모드 지도 카메라 팔로우 — Mock 트래킹 중 카메라가 가상 경로 끝을 따라가고 커스텀 현재위치 마커 표시 (실 GPS의 `.userLocation` 팔로우는 변경 없음, `LaunchFlags.useMockSensors` 분기)
- [x] Mock 주행 테스트 자동화 — `scripts/mockride.sh`(run/start/pause/resume/stop/shot/ui) + `.claude/skills/mock-ride` 스킬 + `.mcp-artifacts/` 산출물 디렉터리, 주요 버튼에 accessibilityIdentifier 부여
- [x] 앱 시작 시 위치 권한 요청 — RootTabView `.task`에서 When-In-Use 선요청, 트래킹 시작 시 Always 승격은 기존 유지 (2단계 전략)
- [ ] 위치 권한 거부 상태 처리 — `CoreSensorsInterface`에 권한 상태 조회(authorizationStatus) 추가하고, 거부/제한 시 설정 앱 유도 UI 표시
- [x] 백그라운드 센서 계측 로거 추가 — location/motion 콜백에 OSLog 타임스탬프 기록 + 1초 이상 수신 gap 감지 로그. 실기기 백그라운드 검증(아래 항목)의 선행 작업. 조사 결과: CLLocationManager는 현 설정(UIBackgroundModes location + allowsBackgroundLocationUpdates + pausesLocationUpdatesAutomatically=false)으로 백그라운드 동작 확실. 리스크는 CMMotionManager — ① iOS 11+ 일부 기기에서 백그라운드 진입 시 deviceMotion 중단 이력(워크어라운드: 백그라운드 진입 시 stop→restart), ② `.xTrueNorthZVertical` 프레임이 자기 센서+위치를 요구해 화면 잠금 시 yaw 드리프트/값 튐 가능성(문제 시 `.xArbitraryZVertical` 다운그레이드 검토)
- [ ] 백그라운드에서 위치·린앵글 수집 정상 여부 검증 — 실기기 백그라운드 상태에서 location/motion 스트림이 끊기지 않고 수집되는지 확인. 상태 3종 구분 측정: 포그라운드(기준선)/홈 화면 배경/화면 잠금. 측정 항목: location 콜백 간격(~1Hz), motion 콜백 간격(0.2s), 백그라운드 진입 전후 gap, motion 콜백이 유지돼도 roll/yaw 값 정상 여부(자기 센서 열화 감지)
- [ ] 백그라운드 메모리·배터리 사용량 측정 — 장시간 트래킹 시 Instruments(Allocations/Energy Log) 또는 MetricKit으로 프로파일링, 위치 정확도/모션 주기 튜닝 근거 마련
- [x] 깨진 LeanAngleAnalyzer 테스트 2건 수정 — 실제 원인은 좌표계 불일치: 구현은 CMDeviceMotion xTrueNorthZVertical(NWU)인데 테스트 픽스처가 ENU 가정으로 작성됨. 픽스처를 NWU로 수정, 무의미하게 통과하던 좌우 부호 테스트도 실질 검증하도록 보강
- [ ] TourStore 단위 테스트 작성 — pause/resume/stop/restore 상태머신 검증 + RideSessionRuntime 동기화 검증(start/pause/resume/stop/restore → 화면잠금 active `true/true/true/false/true`, willEnterForeground 재적용). mock sensors/analyzer/repository/sessionStore + 기록형 RideSessionRuntime fake 필요 (#10 리뷰 Minor에서 확장)

## AI 워크플로 고도화

- [ ] 스캐폴딩 스킬화 — `make feature name=X` 후 수동으로 하던 ModuleName.swift case 등록까지 자동화하는 스킬(`.claude/skills/`) 작성
- [x] 브랜치/PR 기반 git 워크플로 정착 — CLAUDE.md 워크플로 규칙에 반영 (feature/fix 브랜치 → PR(검증 결과 포함) → squash merge, 소규모 docs/chore는 main 직접 허용)
- [ ] 커스텀 스킬 추가 확충 — mock-ride·스캐폴딩 외에 반복 워크플로 스킬화. 후보: ① 빌드+관련 모듈 테스트+시뮬레이터 확인까지 한 번에 도는 검증 스킬, ② PR 생성 스킬(브랜치 규칙·본문 템플릿·검증 결과 자동 포함), ③ MVI Store 테스트 보일러플레이트 생성 스킬
- [ ] GitHub MCP 도입 검토 — 현행 gh CLI 방식과 비교해 장단점(토큰 관리, 컨텍스트 비용, PR 리뷰 코멘트 접근성 등) 정리 후 도입 여부 결정. 도입 시 `.mcp.json`에 등록
- [x] 검증 분리 — ① 커밋 게이트 훅: `.claude/hooks/require-build-test.sh` + `.claude/settings.json` PreToolUse 훅으로 git commit 전 앱 빌드+변경 모듈 테스트 강제, ② 로컬 리뷰: CLAUDE.md에 "PR 생성 전 /code-review" 규칙 추가 (커스텀 리뷰 에이전트는 내장 /code-review로 충분한지 써본 뒤 판단)
- [x] Codex 위임 워크플로 도입 — 빌드+테스트 검증과 PR 전 리뷰를 Codex(openai-codex 플러그인)로 위임해 Claude 토큰 사용량 절감. mock ride는 Codex 샌드박스의 CoreSimulatorService 차단으로 위임 불가 확인, Claude 직접 실행 유지. 커밋 게이트는 빌드 직접 실행 대신 검증 스탬프(`scripts/verify-stamp.sh`) 검사로 전환, git·PR은 Claude 유지. Codex 지침은 AGENTS.md
- [ ] mock ride 검증의 스크린샷 비용 절감 — 속도·린앵글·이벤트 배지 등 수치 검증은 `mockride.sh ui`(접근성 트리 텍스트)로 확인하고, 스크린샷은 화면 확인용 1장으로 축소. CLAUDE.md mock ride 규칙에 원칙 한 줄 추가
- [ ] Codex mock ride 위임 재검토 — 셸 제어는 샌드박스에 막히지만 XcodeBuildMCP MCP 도구는 동작하므로, ui-automation 워크플로를 MCP에 활성화하고 mockride.sh 흐름을 MCP 도구 호출로 포팅하면 가능할 수 있음. 복잡도 대비 절감 효과(스크린샷 1~2장 수준) 작아 보류
- [ ] Codex 자동 review gate(Stop 훅) 활성화 재검토 — 현재 토큰 절약을 위해 비활성. Codex 위임 운영 경험이 쌓이면 `/codex:setup`으로 활성화 여부 재판단

## 발견된 이슈 (조사 필요)

- [ ] AppDIContainer 싱글턴 resolve가 스레드 안전하지 않음 — 캐시 확인과 factory 실행 사이 락이 없어 동시 resolve 시 인스턴스가 중복 생성될 수 있음. 현재는 모든 resolve가 메인 스레드라 실해는 없지만, 백그라운드 resolve가 생기면 문제 (계측 로거 코드리뷰에서 발견)
- [ ] FeatureHistory Demo 타겟 빌드 깨짐 — `FeatureHistoryDemoView.swift`가 존재하지 않는 `HistoryFeatureBuilder.build()`를 참조(실제 어셈블러는 `HistoryAssembler`). FeatureHistory 스킴 테스트 실행이 막힌다(단 실제 테스트 함수는 0개, 앱 빌드로 Impl 컴파일은 검증됨). Demo를 `HistoryAssembler` 기반으로 수정 필요 (History 셀 재구성 작업 중 발견)

- [x] 세션 복구 시 analyzer가 새 인스턴스라 이전 주행 거리/통계가 0부터 시작 → `restoreStats` 시딩 API로 해결 (#7). fetchTour id 무시 버그도 함께 수정
- [x] Tuist manifest에 FeatureTour → CoreDataStorageInterface 의존성 누락 → implementationDependencies 선언으로 해결 (#7)
- [x] `updateStats()`가 매초 repository에 쓰기 — 오탐 판정: 스로틀이 repository 내부에 있어 README("30회마다 저장")와 실질 일치. 진짜 문제였던 finishTour 최종 저장이 스로틀에 막히는 버그를 수정 (#7)
- [ ] FeatureSettings 개발 — TrackingPolicy 임계값(급가속/뱅킹각/정차 기준)을 설정 화면과 연결
- [ ] 린앵글 오일러 폴백 → 중력 투영 전환 시 값 불연속 — course 최초 확보 순간 계산 방식이 바뀌며 표시값이 점프할 수 있음(경사 보정 유무 차이). 실주행 영향은 주행 시작 직후 한 번뿐이라 낮음, 필요 시 스무딩 검토
- [ ] mockride.sh가 스테일 앱을 설치할 수 있음 — `run`이 `~/Library/Developer/Xcode/DerivedData`를 `find | head -1`로 잡는데 ① XcodeBuildMCP 빌드 산출물은 자체 워크스페이스 경로(`~/Library/Developer/XcodeBuildMCP/workspaces/`)에 생겨 탐색 대상 밖 ② 워크트리별 DerivedData가 여럿일 때 head -1이 mtime 무관 임의 선택. 경사각 수정 검증 중 수정 전 앱이 설치돼 검증이 무효화될 뻔함(실측). 개선안: mtime 최신 선택 + XcodeBuildMCP 경로 포함, 또는 앱 경로 인자 지원
- [ ] 경사각 절대 기준 부재 — 차체 축을 첫 주행 샘플에서 캡처하므로(#PR) 경사에서 출발/재개하면 그 지점 경사가 0으로 잡혀 이후 표시가 오프셋된다(예: +8° 언덕 출발 → 거기 0°, 평지 −8°). 린 영점 캘리브레이션과 동일한 IMU 단독 추정의 한계. 표시 전용이라 영향은 낮음. 절대 경사가 필요하면 GPS 고도Δ/거리 기반 독립 추정 검토 (Codex 리뷰 P2, 알려진 한계로 수용)
