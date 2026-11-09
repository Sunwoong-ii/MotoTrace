//
//  TrackingThresholdsRepository.swift
//  CoreDataStorage
//

import Foundation
import CoreDataStorageInterface
import CoreTrackingInterface

/// UserDefaults를 사용해 주행 임계값을 저장/복원하는 구현체
public final class TrackingThresholdsRepository: TrackingThresholdsRepositoryInterface {
    private let defaults: UserDefaults
    private let key = "com.mototrace.trackingThresholds"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> TrackingThresholds {
        guard let data = defaults.data(forKey: key),
              let thresholds = try? JSONDecoder().decode(TrackingThresholds.self, from: data)
        else { return TrackingPolicy.defaultThresholds }
        return thresholds
    }

    public func save(_ thresholds: TrackingThresholds) {
        guard let data = try? JSONEncoder().encode(thresholds) else { return }
        defaults.set(data, forKey: key)
    }
}
