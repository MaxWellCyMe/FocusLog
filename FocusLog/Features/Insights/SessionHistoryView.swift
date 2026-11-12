//
//  SessionHistoryView.swift
//  FocusLog
//

import SwiftData
import SwiftUI

private struct SessionDay: Identifiable {
    let date: Date
    let sessions: [FocusSession]

    var id: Date { date }
}

struct SessionHistoryView: View {
    @Query(sort: \FocusSession.completedAt, order: .reverse) private var sessions: [FocusSession]
    @State private var searchText = ""

    private var filteredSessions: [FocusSession] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter {
            ($0.taskTitle ?? "Open focus session").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sections: [SessionDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.completedAt)
        }
        return grouped
            .map { SessionDay(date: $0.key, sessions: $0.value.sorted { $0.completedAt > $1.completedAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if sections.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No completed sessions" : "No matching sessions",
                    systemImage: searchText.isEmpty ? "timer" : "magnifyingglass"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(sections) { section in
                    Section(section.date.formatted(.dateTime.weekday(.wide).month(.wide).day())) {
                        ForEach(section.sessions) { session in
                            HStack(spacing: 12) {
                                Image(systemName: "timer")
                                    .foregroundStyle(Color.indigo)
                                    .frame(width: 34, height: 34)
                                    .background(Color.indigo.opacity(0.10), in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(session.taskTitle ?? "Open focus session")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Text(session.completedAt, format: .dateTime.hour().minute())
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(session.durationSeconds / 60)m")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
        .navigationTitle("Session history")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search task names")
    }
}

#Preview {
    NavigationStack {
        SessionHistoryView()
    }
    .modelContainer(for: FocusSession.self, inMemory: true)
}
