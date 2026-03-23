//
//  TrackingSessionRepository.swift
//  CoreDataStorage
//
//  Created by Woong on 2026/03/23.
//

import Foundation
import CoreDataStorageInterface

/// UserDefaults를 사용해 트래킹 세션 메타데이터를 저장/복원하는 구현체
public final class TrackingSessionRepository: TrackingSessionRepositoryInterface {
    private let defaults: UserDefaults
    private let key = "com.mototrace.activeTrackingSession"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func save(_ session: ActiveTrackingSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: key)
    }

    public func load() -> ActiveTrackingSession? {
        guard let data = defaults.data(forKey: key),
              let session = try? JSONDecoder().decode(ActiveTrackingSession.self, from: data)
        else { return nil }
        return session
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}
