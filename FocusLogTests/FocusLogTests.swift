//
//  FocusLogTests.swift
//  FocusLogTests
//

import XCTest
@testable import FocusLog

@MainActor
final class FocusTimerControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var storageKey: String!

    override func setUp() {
        super.setUp()
        let suiteName = "FocusLogTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        storageKey = "timer.snapshot"
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.volatileDomainNames.first ?? "")
        defaults = nil
        storageKey = nil
        super.tearDown()
    }

    func testFocusCompletionTransitionsToShortBreak() {
        let controller = FocusTimerController(storage: defaults, storageKey: storageKey)
        let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

        controller.start(at: start)
        let completion = controller.complete(at: start.addingTimeInterval(25 * 60))

        XCTAssertEqual(completion?.phase, .focus)
        XCTAssertEqual(completion?.durationSeconds, 25 * 60)
        XCTAssertEqual(controller.phase, .shortBreak)
        XCTAssertEqual(controller.status, .finished)
        XCTAssertEqual(controller.remainingSeconds(at: start), 5 * 60)
        XCTAssertEqual(controller.completedFocusRounds, 1)
    }

    func testEveryFourthFocusCompletionTransitionsToLongBreak() {
        let controller = FocusTimerController(storage: defaults, storageKey: storageKey)
        var date = Date(timeIntervalSinceReferenceDate: 2_000_000)

        for round in 1...4 {
            controller.start(at: date)
            _ = controller.complete(at: date.addingTimeInterval(25 * 60))
            date = date.addingTimeInterval(25 * 60)

            if round < 4, controller.phase.isBreak {
                controller.start(at: date)
                _ = controller.complete(at: date.addingTimeInterval(TimeInterval(controller.phase.durationMinutes * 60)))
                date = date.addingTimeInterval(TimeInterval(controller.phase.durationMinutes * 60))
            }
        }

        XCTAssertEqual(controller.completedFocusRounds, 4)
        XCTAssertEqual(controller.phase, .longBreak)
        XCTAssertEqual(controller.remainingSeconds(at: date), 15 * 60)
    }

    func testPausedTimerRestoresItsRemainingTime() {
        let start = Date(timeIntervalSinceReferenceDate: 3_000_000)
        let controller = FocusTimerController(storage: defaults, storageKey: storageKey)
        controller.start(at: start)
        controller.pause(at: start.addingTimeInterval(9 * 60))

        let restored = FocusTimerController(storage: defaults, storageKey: storageKey)

        XCTAssertEqual(restored.status, .paused)
        XCTAssertEqual(restored.remainingSeconds(at: start), 16 * 60)
        XCTAssertEqual(restored.phase, .focus)
    }
}

final class FocusInsightsCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testDailyTotalsIncludesDaysWithoutSessions() {
        let today = date(year: 2026, month: 11, day: 12)
        let sessions = [
            FocusSession(startedAt: today, completedAt: today, durationSeconds: 25 * 60),
            FocusSession(startedAt: today, completedAt: today, durationSeconds: 45 * 60)
        ]

        let totals = FocusInsightsCalculator.dailyTotals(sessions: sessions, calendar: calendar, now: today, dayCount: 3)

        XCTAssertEqual(totals.count, 3)
        XCTAssertEqual(totals.map(\.minutes), [0, 0, 70])
    }

    func testCurrentStreakStopsAtFirstMissingDay() {
        let today = date(year: 2026, month: 11, day: 12)
        let sessions = [0, 1, 2, 4].map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return FocusSession(startedAt: date, completedAt: date, durationSeconds: 25 * 60)
        }

        XCTAssertEqual(FocusInsightsCalculator.currentStreak(sessions: sessions, calendar: calendar, now: today), 3)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
