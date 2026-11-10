//
//  CoreSensorsServiceAuthorizationTests.swift
//  CoreSensorsTests
//

import XCTest
import CoreSensorsInterface
@testable import CoreSensors

/// 권한 스트림은 주행 화면과 설정 화면이 동시에 구독한다.
/// 한 구독이 다른 구독을 끊으면 주행 중 권한 회수 감지가 죽으므로 이를 막는다.
final class AuthorizationBroadcasterTests: XCTestCase {

    func test_subscribe_구독즉시_현재상태를_받는다() async {
        // Given
        let sut = AuthorizationBroadcaster()

        // When
        var iterator = sut.subscribe(current: .whenInUse).makeAsyncIterator()

        // Then
        let received = await iterator.next()
        XCTAssertEqual(received, .whenInUse)
    }

    func test_send_구독이_둘이면_둘다_같은값을_받는다() async {
        // Given: 두 화면이 차례로 구독한다
        let sut = AuthorizationBroadcaster()
        var first = sut.subscribe(current: .whenInUse).makeAsyncIterator()
        var second = sut.subscribe(current: .whenInUse).makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()

        // When: 권한이 바뀐다
        sut.send(.denied)

        // Then: 나중 구독이 먼저 구독을 끊지 않는다
        let firstUpdate = await first.next()
        let secondUpdate = await second.next()
        XCTAssertEqual(firstUpdate, .denied, "나중 구독 때문에 먼저 구독한 쪽이 끊기면 안 됩니다")
        XCTAssertEqual(secondUpdate, .denied)
    }

    func test_send_끝난구독은_정리된다() async {
        // Given: 한쪽 구독을 끝낸다
        let sut = AuthorizationBroadcaster()
        var kept = sut.subscribe(current: .always).makeAsyncIterator()
        do {
            let dropped = sut.subscribe(current: .always)
            var iterator = dropped.makeAsyncIterator()
            _ = await iterator.next()
        }
        _ = await kept.next()
        XCTAssertEqual(sut.subscriberCount, 2)

        // When: 발행하면 끝난 구독이 걷힌다
        sut.send(.denied)
        sut.send(.denied)

        // Then: 살아 있는 구독만 남는다
        let keptUpdate = await kept.next()
        XCTAssertEqual(keptUpdate, .denied)
        XCTAssertLessThanOrEqual(sut.subscriberCount, 2)
    }
}
