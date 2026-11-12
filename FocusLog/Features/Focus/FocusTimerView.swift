//
//  FocusTimerView.swift
//  FocusLog
//

import Combine
import SwiftData
import SwiftUI

struct FocusTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusTask.createdAt, order: .reverse) private var tasks: [FocusTask]
    @Query(sort: \FocusSession.completedAt, order: .reverse) private var sessions: [FocusSession]

    @State private var timer = FocusTimerController()
    @State private var now = Date.now

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let durations = [15, 25, 45, 60]

    private var todaySessions: [FocusSession] {
        sessions.filter { Calendar.current.isDateInToday($0.completedAt) }
    }

    private var todayMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.durationSeconds / 60 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                header
                timerDial
                planControls
                actionControls
                dailySummary
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(clock) { date in
                now = date
                completeIfTimeIsUp(at: date)
            }
            .onAppear {
                now = .now
                completeIfTimeIsUp(at: .now)
                Task { await FocusTimerNotificationService.synchronize(for: timer) }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text(statusTitle)
                .font(.system(size: 21, weight: .bold, design: .rounded))
            Text(statusSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var timerDial: some View {
        ZStack {
            Circle()
                .stroke(Color.indigo.opacity(0.10), lineWidth: 12)
            Circle()
                .trim(from: 0, to: min(timer.progress(at: now), 1))
                .stroke(Color.indigo.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: timer.remainingSeconds(at: now))

            VStack(spacing: 4) {
                Text(timer.formattedTime(at: now))
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue(timer.formattedTime(at: now))

                Text(dialCaption)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 250, height: 250)
        .padding(.vertical, 4)
    }

    private var planControls: some View {
        Group {
            if timer.phase == .focus {
                VStack(spacing: 14) {
                    Picker("Focus task", selection: selectedTaskBinding) {
                        Text("Choose a task").tag(Optional<String>.none)
                        ForEach(tasks) { task in
                            Text(task.title).tag(Optional(task.title))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!timer.canEditPlan || tasks.isEmpty)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                    Picker("Focus duration", selection: durationBinding) {
                        ForEach(durations, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!timer.canEditPlan)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: timer.phase == .longBreak ? "bed.double.fill" : "cup.and.saucer.fill")
                        .foregroundStyle(Color.teal)
                        .frame(width: 38, height: 38)
                        .background(Color.teal.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(timer.phase.title) · \(timer.phase.durationMinutes) min")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text("Rest is part of a sustainable focus cycle.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var actionControls: some View {
        HStack(spacing: 14) {
            if timer.status == .running || timer.status == .paused {
                Button(action: resetTimer) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 54, height: 54)
                        .foregroundStyle(.primary)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset timer")
            }

            Button(action: primaryAction) {
                Label(primaryActionTitle, systemImage: primaryActionSymbol)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(.white)
                    .background(Color.indigo, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(timer.status == .running && timer.remainingSeconds(at: now) == 0)
        }
        .frame(maxWidth: 420)
    }

    private var dailySummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.green)
            Text("\(todaySessions.count) sessions")
            Text("·").foregroundStyle(.tertiary)
            Text("\(todayMinutes) focused min")
            Text("·").foregroundStyle(.tertiary)
            Text("Round \(timer.cyclePosition) of 4")
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }

    private var statusTitle: String {
        switch timer.status {
        case .idle: "Ready when you are"
        case .running: timer.phase.isBreak ? "Step away for a moment" : "Stay with one thing"
        case .paused: timer.phase.isBreak ? "Your break is paused" : "Your focus is paused"
        case .finished: timer.phase.isBreak ? "Nice work. Take a break." : "Break complete. Ready to focus?"
        }
    }

    private var statusSubtitle: String {
        if timer.phase.isBreak {
            return timer.status == .finished
                ? "Your next \(timer.phase.title.lowercased()) is ready when you are."
                : "Rest for \(timer.phase.durationMinutes) minutes, then return refreshed."
        }
        if let taskTitle = timer.taskTitle {
            return taskTitle
        }
        return timer.status == .idle ? "Choose a task or focus on anything." : "A single focused session at a time."
    }

    private var primaryActionTitle: String {
        switch timer.status {
        case .idle: "Start focusing"
        case .finished: timer.phase.isBreak ? "Start \(timer.phase.title.lowercased())" : "Start focusing"
        case .running: "Pause"
        case .paused: "Resume"
        }
    }

    private var primaryActionSymbol: String {
        switch timer.status {
        case .idle: "play.fill"
        case .finished: timer.phase.isBreak ? "cup.and.saucer.fill" : "play.fill"
        case .running: "pause.fill"
        case .paused: "play.fill"
        }
    }

    private var dialCaption: String {
        switch timer.status {
        case .paused: "PAUSED · \(timer.phase.title.uppercased())"
        case .finished: "UP NEXT · \(timer.phase.title.uppercased())"
        case .idle, .running: timer.phase.title.uppercased()
        }
    }

    private var selectedTaskBinding: Binding<String?> {
        Binding(
            get: { timer.taskTitle },
            set: { timer.selectTask($0) }
        )
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { timer.selectedMinutes },
            set: { timer.selectDuration($0) }
        )
    }

    private func primaryAction() {
        switch timer.status {
        case .idle, .finished:
            timer.start(at: now)
        case .running:
            timer.pause(at: now)
        case .paused:
            timer.resume(at: now)
        }
        Task { await FocusTimerNotificationService.synchronize(for: timer) }
    }

    private func completeIfTimeIsUp(at date: Date) {
        guard let completion = timer.complete(at: date) else { return }
        FocusTimerNotificationService.cancel()
        guard completion.phase == .focus else { return }
        modelContext.insert(FocusSession(
            startedAt: completion.startedAt,
            completedAt: date,
            durationSeconds: completion.durationSeconds,
            taskTitle: completion.taskTitle
        ))
    }

    private func resetTimer() {
        timer.reset()
        FocusTimerNotificationService.cancel()
    }
}

#Preview {
    FocusTimerView()
        .modelContainer(for: [FocusTask.self, FocusSession.self], inMemory: true)
}
