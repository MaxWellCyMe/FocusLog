//
//  FocusInsightsCalculator.swift
//  FocusLog
//

import Foundation

struct FocusDailyTotal: Identifiable, Equatable {
    let date: Date
    let minutes: Int

    var id: Date { date }
}

enum FocusInsightsCalculator {
    static func dailyTotals(
        sessions: [FocusSession],
        calendar: Calendar = .current,
        now: Date = .now,
        dayCount: Int = 7
    ) -> [FocusDailyTotal] {
        let today = calendar.startOfDay(for: now)
        let secondsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.completedAt)
        }
        .mapValues { daySessions in
            daySessions.reduce(0) { $0 + $1.durationSeconds }
        }

        return (0..<dayCount).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return FocusDailyTotal(date: date, minutes: (secondsByDay[date] ?? 0) / 60)
        }
    }

    static func currentStreak(sessions: [FocusSession], calendar: Calendar = .current, now: Date = .now) -> Int {
        let focusedDays = Set(sessions.map { calendar.startOfDay(for: $0.completedAt) })
        var date = calendar.startOfDay(for: now)
        var streak = 0

        while focusedDays.contains(date) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return streak
    }
}
