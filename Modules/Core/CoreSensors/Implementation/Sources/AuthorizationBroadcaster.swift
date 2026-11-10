//
//  AuthorizationBroadcaster.swift
//  CoreSensors
//

import Foundation
import CoreSensorsInterface

/// 권한 상태를 여러 구독자에게 같이 흘린다.
/// AsyncStream은 소비자가 하나뿐이라 구독마다 스트림을 따로 발급하고 continuation을 모아둔다.
/// 주행 화면과 설정 화면이 동시에 구독하므로, 한 구독이 다른 구독을 끊으면 안 된다.
/// 구독·발행 모두 메인 스레드(델리게이트 콜백, @MainActor Store)에서 일어난다고 본다.
final class AuthorizationBroadcaster {
    private var continuations: [UUID: AsyncStream<LocationAuthorizationStatus>.Continuation] = [:]

    /// 구독 즉시 현재 상태를 한 번 흘린다
    func subscribe(current: LocationAuthorizationStatus) -> AsyncStream<LocationAuthorizationStatus> {
        let (stream, continuation) = AsyncStream.makeStream(of: LocationAuthorizationStatus.self)
        continuations[UUID()] = continuation
        continuation.yield(current)
        return stream
    }

    func send(_ status: LocationAuthorizationStatus) {
        // 끝난 구독은 발행하면서 함께 걷어낸다 — onTermination으로 지우면
        // 임의 스레드에서 딕셔너리를 건드리게 된다
        for (id, continuation) in continuations {
            if case .terminated = continuation.yield(status) {
                continuations[id] = nil
            }
        }
    }

    /// 테스트용 — 살아 있는 구독 수
    var subscriberCount: Int { continuations.count }
}
