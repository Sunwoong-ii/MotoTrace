//
//  TrackingThresholdsRepositoryInterface.swift
//  CoreDataStorageInterface
//

import Foundation
import CoreTrackingInterface

/// 사용자가 조정한 주행 이벤트 임계값 영속화 담당
public protocol TrackingThresholdsRepositoryInterface: AnyObject {
    /// 저장된 값이 없으면 기본 임계값을 돌려준다
    func load() -> TrackingThresholds
    func save(_ thresholds: TrackingThresholds)
}
