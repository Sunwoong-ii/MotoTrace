//  SensorStreamInstrumentationTests.swift
//  CoreSensorsTests
//
//  Created by Woong on 2026/07/10.
//

import XCTest
@testable import CoreSensors

/// 백그라운드 검증의 핵심 신호가 gap 경고 로그이므로, 임계값 판정이
/// 오탐(정상 주기 경고)·미탐(공백 누락) 없이 동작하는지 고정 타임스탬프로 검증
final class SensorStreamInstrumentationTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_000_000)

    func test_gap판정_첫콜백은_직전수신이없어_gap없음() {
        // Given
        let instrumentation = SensorStreamInstrumentation(category: "test", gapThreshold: 1.0)

        // When
        let gap = instrumentation.recordCallback(timestamp: base)

        // Then
        XCTAssertNil(gap)
    }

    func test_gap판정_임계값미만간격은_gap없음() {
        // Given: 5Hz 모션 명목 주기(0.2초) 수준의 간격
        let instrumentation = SensorStreamInstrumentation(category: "test", gapThreshold: 1.0)
        instrumentation.recordCallback(timestamp: base)

        // When
        let gap = instrumentation.recordCallback(timestamp: base.addingTimeInterval(0.2))

        // Then
        XCTAssertNil(gap)
    }

    func test_gap판정_임계값이상간격은_gap반환() {
        // Given
        let instrumentation = SensorStreamInstrumentation(category: "test", gapThreshold: 1.0)
        instrumentation.recordCallback(timestamp: base)

        // When: 백그라운드 진입으로 콜백이 1.5초 끊긴 상황
        let gap = instrumentation.recordCallback(timestamp: base.addingTimeInterval(1.5))

        // Then
        XCTAssertEqual(gap ?? 0, 1.5, accuracy: 0.001)
    }

    func test_gap판정_공백이후정상주기복귀시_gap없음() {
        // Given: gap 발생 후 마지막 수신 시각이 갱신되어야 연속 오탐이 없음
        let instrumentation = SensorStreamInstrumentation(category: "test", gapThreshold: 1.0)
        instrumentation.recordCallback(timestamp: base)
        instrumentation.recordCallback(timestamp: base.addingTimeInterval(2.0))

        // When
        let gap = instrumentation.recordCallback(timestamp: base.addingTimeInterval(2.2))

        // Then
        XCTAssertNil(gap)
    }
}
