//
//  InsightsView.swift
//  FocusLog
//

import Charts
import Foundation
import SwiftData
import SwiftUI

struct InsightsView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \FocusSession.completedAt, order: .reverse) private var sessions: [FocusSession]

    private let calendar = Calendar.current

    private var weeklyData: [FocusDailyTotal] {
        FocusInsightsCalculator.dailyTotals(sessions: sessions, calendar: calendar)
    }

    private var weeklySessions: [FocusSession] {
        guard let start = weeklyData.first?.date else { return [] }
        return sessions.filter { $0.completedAt >= start }
    }

    private var previousWeekSessions: [FocusSession] {
        guard
            let start = weeklyData.first?.date,
            let previousStart = calendar.date(byAdding: .day, value: -7, to: start)
        else { return [] }
        return sessions.filter { $0.completedAt >= previousStart && $0.completedAt < start }
    }

    private var weeklyMinutes: Int {
        weeklySessions.reduce(0) { $0 + $1.durationSeconds / 60 }
    }

    private var previousWeeklyMinutes: Int {
        previousWeekSessions.reduce(0) { $0 + $1.durationSeconds / 60 }
    }

    private var activeDays: Int {
        weeklyData.filter { $0.minutes > 0 }.count
    }

    private var currentStreak: Int {
        FocusInsightsCalculator.currentStreak(sessions: sessions, calendar: calendar)
    }

    private var comparisonText: String {
        guard previousWeeklyMinutes > 0 else {
            return weeklyMinutes > 0 ? "Your first focused week is underway." : "Start a session to reveal your rhythm."
        }

        let change = Int((Double(weeklyMinutes - previousWeeklyMinutes) / Double(previousWeeklyMinutes) * 100).rounded())
        if change > 0 { return "Up \(change)% from the previous 7 days." }
        if change < 0 { return "Down \(abs(change))% from the previous 7 days." }
        return "Matching your previous 7 days."
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.insightsPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    keyMetrics
                    focusChart
                    consistencyCard
                    recentSessions
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRoute.self, destination: destination)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR FOCUS RHYTHM")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.25)
                .foregroundStyle(Color.indigo)
            Text("See your momentum")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(comparisonText)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyMetrics: some View {
        HStack(spacing: 10) {
            MetricCard(
                title: "FOCUS TIME",
                value: "\(weeklyMinutes)",
                unit: "min this week",
                symbol: "clock.fill",
                tint: .indigo
            )
            MetricCard(
                title: "SESSIONS",
                value: "\(weeklySessions.count)",
                unit: "completed",
                symbol: "checkmark.seal.fill",
                tint: .green
            )
        }
    }

    private var focusChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last 7 days")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                    Text("Minutes of completed focus")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(activeDays)/7 days")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if weeklyMinutes == 0 {
                chartEmptyState
            } else {
                Chart(weeklyData) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(day.minutes > 0 ? Color.indigo : Color.indigo.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.quaternary)
                        AxisValueLabel {
                            if let minutes = value.as(Int.self), minutes > 0 {
                                Text("\(minutes)m")
                            }
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 190)
                .accessibilityLabel("Focus time over the last 7 days")
                .accessibilityValue("\(weeklyMinutes) minutes over \(activeDays) active days")
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var chartEmptyState: some View {
        VStack(spacing: 9) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 27, weight: .light))
                .foregroundStyle(Color.indigo.opacity(0.70))
            Text("Your weekly chart will appear here")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            Text("Finish a focus session to begin building your history.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
    }

    private var consistencyCard: some View {
        HStack(spacing: 16) {
            Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(currentStreak > 0 ? Color.orange : Color.secondary.opacity(0.55))
                .frame(width: 42, height: 42)
                .background(Color.orange.opacity(currentStreak > 0 ? 0.14 : 0.08), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(currentStreak == 0 ? "Build a focused streak" : "\(currentStreak)-day focus streak")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(currentStreak == 0 ? "Complete a session today to begin." : "Keep showing up, one session at a time.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent sessions")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Spacer()
                if !sessions.isEmpty {
                    Button("View all") { router.showSessionHistory() }
                        .font(.system(size: 13, weight: .semibold))
                }
            }

            if sessions.isEmpty {
                Text("Completed sessions will be saved here.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(sessions.prefix(3)) { session in
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.indigo)
                            .frame(width: 32, height: 32)
                            .background(Color.indigo.opacity(0.10), in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.taskTitle ?? "Open focus session")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                            Text(session.completedAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(session.durationSeconds / 60)m")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .sessionHistory:
            SessionHistoryView()
        default:
            EmptyView()
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(unit)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [FocusTask.self, FocusSession.self], inMemory: true)
}
