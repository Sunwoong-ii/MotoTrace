---
name: mock-ride
description: Mock 센서 가상 주행으로 시뮬레이터에서 트래킹 플로우를 실행·검증한다. 시뮬레이터에서 트래킹 UI를 확인하거나, 라이딩 관련 변경(센서·분석·지도·통계)을 실기기 없이 테스트하거나, 스크린샷 검증이 필요할 때 사용.
---

# Mock 주행 테스트

`scripts/mockride.sh`로 시뮬레이터에서 가상 주행을 자동 실행한다. UI 요소는 접근성 식별자로 탐색하므로 snapshot-ui로 ref를 재발견할 필요 없다.

## 사용법

```bash
scripts/mockride.sh run              # 부팅 → 설치 → -UseMockSensors로 실행 (앱은 미리 빌드돼 있어야 함)
scripts/mockride.sh start [투어이름]  # START RECORDING → 이름 alert → 시작 (이름 생략 시 기본 이름)
scripts/mockride.sh pause / resume / stop
scripts/mockride.sh shot [라벨]       # 스크린샷 → .mcp-artifacts/<세션>/<시각>_<라벨>.jpg
scripts/mockride.sh ui               # 화면 요소 ref 목록 (디버깅용)
```

빌드가 필요하면 먼저: `xcodebuild -workspace MotoTrace.xcworkspace -scheme MotoTrace -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

스크린샷은 Read 도구로 열어 확인한다. 산출물은 `.mcp-artifacts/`(gitignore 대상)에 세션 단위로 쌓인다.

## Mock 시나리오 타임라인 (105초 루프)

| 구간 | 시간 | 내용 | 기대 결과 |
|---|---|---|---|
| 정차 | 0–5s | 0 km/h | 린앵글 영점 캘리브레이션 |
| 급가속 | 5–10s | 0→100 km/h | 급가속 이벤트 (20 ≥ 임계 16.7 km/h/s) |
| 정속 | 10–35s | 100 km/h | |
| 완만 감속 | 35–40s | 100→70 | 이벤트 없음 |
| 우코너 | 40–46s | heading 0→90°, lean +34.7° | 뱅킹각 이벤트 (≥30°) |
| 직선 | 46–65s | 70 km/h 동진 | |
| 좌코너 | 65–71s | heading 90→0°, lean −34.7° | 뱅킹각 이벤트 |
| 완만 가속 | 71–85s | 70→100 | 이벤트 없음 |
| 급제동 | 85–90s | 100→0 | 급감속 이벤트 |
| 정차 | 90–105s | 0 km/h | 정차 구간 (주행 시간·거리 제외) |

경로는 북한강 인근(37.5665, 127.3066)에서 시작해 dead reckoning으로 이어진다 (실제 도로를 따라가지는 않음).

## 검증 포인트

- 트래킹 중 속도·린앵글 게이지가 시나리오대로 변하는지 (`shot`으로 확인)
- Max Angle이 34.7°에 수렴하는지 (시나리오 설계값)
- **Mock 모드에서는 카메라가 경로 끝(파란 마커)을 따라감** — 실 GPS의 `.userLocation` 팔로우와 별개 분기 (TourView.swift, `LaunchFlags.useMockSensors`)
- 종료 후 History 탭에서 거리·시간·평균/최고 속도·최대 뱅킹각 저장 확인

## 접근성 식별자

`startRecordingButton`, `pauseResumeButton`, `stopButton`, `currentPositionButton`. 투어 이름 alert의 버튼은 label("시작"/"취소")로 탐색.
