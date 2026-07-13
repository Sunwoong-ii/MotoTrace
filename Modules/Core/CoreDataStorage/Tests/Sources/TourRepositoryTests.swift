//
//  TourRepositoryTests.swift
//  CoreDataStorageTests
//

import XCTest
import SwiftData
import CoreDataStorageInterface
@testable import CoreDataStorage

final class TourRepositoryTests: XCTestCase {

    var sut: TourRepository!

    override func setUp() {
        super.setUp()
        // in-memory 컨테이너 — 디스크 오염 없이 실제 SwiftData 쿼리 경로를 검증
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: TourRecord.self, LocationPoint.self, TourEvent.self,
            configurations: config
        )
        sut = TourRepository(modelContainer: container)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeTour(name: String, createdAt: Date = Date()) -> TourRecordDTO {
        TourRecordDTO(tourName: name, createdAt: createdAt)
    }

    // MARK: - 1. fetchTour id 조회

    func test_fetchTour_투어_여러개중_지정한_id의_투어_반환() async throws {
        // Given: 생성 시각이 다른 투어 2개 (older가 fetch 순서상 앞에 오도록)
        let older = makeTour(name: "이틀 전 투어", createdAt: Date(timeIntervalSinceNow: -172800))
        let target = makeTour(name: "진행 중이던 투어")
        try await sut.createTour(older)
        try await sut.createTour(target)

        // When: 특정 id로 조회
        let fetched = try await sut.fetchTour(id: target.id)

        // Then: 지정한 id의 투어가 반환되어야 함
        XCTAssertEqual(fetched?.id, target.id, "지정한 id의 투어가 반환되어야 합니다")
        XCTAssertEqual(fetched?.tourName, "진행 중이던 투어",
                       "다른 투어(가장 오래된 것 등)가 아닌 요청한 투어여야 합니다")
    }

    func test_fetchTour_존재하지_않는_id면_nil_반환() async throws {
        // Given
        try await sut.createTour(makeTour(name: "투어"))

        // When
        let fetched = try await sut.fetchTour(id: UUID())

        // Then
        XCTAssertNil(fetched, "존재하지 않는 id는 nil을 반환해야 합니다")
    }

    // MARK: - 2. deleteTour id 삭제

    func test_deleteTour_지정한_id의_투어만_삭제() async throws {
        // Given: 투어 2개
        let keep = makeTour(name: "남길 투어", createdAt: Date(timeIntervalSinceNow: -172800))
        let remove = makeTour(name: "지울 투어")
        try await sut.createTour(keep)
        try await sut.createTour(remove)

        // When: 특정 id 삭제
        try await sut.deleteTour(id: remove.id)

        // Then: 지정한 투어만 사라지고 나머지는 유지
        let all = try await sut.fetchAllTours()
        XCTAssertEqual(all.count, 1, "지정한 투어 하나만 삭제되어야 합니다")
        XCTAssertEqual(all.first?.id, keep.id, "삭제 대상이 아닌 투어는 남아 있어야 합니다")
    }

    // MARK: - 3. finishTour 최종 통계 저장 (스로틀 우회)

    func test_finishTour_스로틀_미달이어도_최종_통계_저장() async throws {
        // Given: 투어 생성 후 통계 업데이트 1회 (30회 스로틀 미달)
        let tour = makeTour(name: "짧은 주행")
        try await sut.createTour(tour)
        let finalStats = TripStats(duration: 197, distance: 3.1, avgSpeed: 62)
        try await sut.updateTripStats(id: tour.id, tripStats: finalStats)

        // When: 트래킹 종료
        try await sut.finishTour(id: tour.id)

        // Then: 스로틀에 막히지 않고 최종 통계가 저장되어야 함
        let saved = try await sut.fetchTour(id: tour.id)
        XCTAssertEqual(saved?.duration ?? 0, 197, accuracy: 0.01,
                       "종료 시점의 최종 duration이 저장되어야 합니다")
        XCTAssertEqual(saved?.distance ?? 0, 3.1, accuracy: 0.01,
                       "종료 시점의 최종 distance가 저장되어야 합니다")
    }
}
