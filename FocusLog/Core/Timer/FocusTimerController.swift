//
//  FocusTimerController.swift
//  FocusLog
//

import Foundation
import Observation

enum FocusTimerStatus: String, Codable, Equatable {
    case idle
    case running
    case paused
    case finished
}

enum FocusTimerPhase: String, Codable, Equatable {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        }
    }

    var durationMinutes: Int {
        switch self {
        case .focus: 0
        case .shortBreak: 5
        case .longBreak: 15
        }
    }

    var isBreak: Bool {
        self != .focus
    }
}

struct FocusTimerCompletion {
    let phase: FocusTimerPhase
    let startedAt: Date
    let durationSeconds: Int
    let taskTitle: String?
}

@Observable
@MainActor
final class FocusTimerController {
    private struct Snapshot: Codable {
        var status: FocusTimerStatus
        var selectedMinutes: Int
        var deadline: Date?
        var pausedSeconds: Int
        var startedAt: Date?
        var taskTitle: String?
        var phase: FocusTimerPhase?
        var completedFocusRounds: Int?
    }

    private let storage: UserDefaults
    private let storageKey: String

    private(set) var status: FocusTimerStatus = .idle
    private(set) var phase: FocusTimerPhase = .focus
    private(set) var selectedMinutes = 25
    private(set) var completedFocusRounds = 0
    private(set) var deadline: Date?
    private(set) var pausedSeconds = 0
    private(set) var startedAt: Date?
    private(set) var taskTitle: String?

    init(storage: UserDefaults = .standard, storageKey: String = "focuslog.timer.snapshot") {
        self.storage = storage
        self.storageKey = storageKey
        restore()
    }

    var canEditPlan: Bool {
        phase == .focus && (status == .idle || status == .finished)
    }

    var cyclePosition: Int {
        completedFocusRounds % 4 + 1
    }

    func remainingSeconds(at date: Date = .now) -> Int {
        switch status {
        case .idle:
            durationSeconds(for: phase)
        case .running:
            max(0, Int(ceil((deadline ?? date).timeIntervalSince(date))))
        case .paused, .finished:
            pausedSeconds
        }
    }

    func progress(at date: Date = .now) -> Double {
        guard status == .running || status == .paused else { return 0 }
        let total = durationSeconds(for: phase)
        guard total > 0 else { return 0 }
        return 1 - Double(remainingSeconds(at: date)) / Double(total)
    }

    func formattedTime(at date: Date = .now) -> String {
        let seconds = remainingSeconds(at: date)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func selectDuration(_ minutes: Int) {
        guard canEditPlan, [15, 25, 45, 60].contains(minutes) else { return }
        selectedMinutes = minutes
        status = .idle
        pausedSeconds = 0
        persist()
    }

    func selectTask(_ title: String?) {
        guard canEditPlan else { return }
        taskTitle = title
        persist()
    }

    func start(at date: Date = .now) {
        guard status == .idle || status == .finished else { return }
        startedAt = date
        deadline = date.addingTimeInterval(TimeInterval(durationSeconds(for: phase)))
        pausedSeconds = 0
        status = .running
        persist()
    }

    func pause(at date: Date = .now) {
        guard status == .running else { return }
        pausedSeconds = remainingSeconds(at: date)
        deadline = nil
        status = .paused
        persist()
    }

    func resume(at date: Date = .now) {
        guard status == .paused else { return }
        deadline = date.addingTimeInterval(TimeInterval(pausedSeconds))
        status = .running
        persist()
    }

    func complete(at date: Date = .now) -> FocusTimerCompletion? {
        guard status == .running, remainingSeconds(at: date) == 0 else { return nil }

        let completedPhase = phase
        let completedDuration = durationSeconds(for: completedPhase)
        let completion = FocusTimerCompletion(
            phase: completedPhase,
            startedAt: startedAt ?? date.addingTimeInterval(-TimeInterval(completedDuration)),
            durationSeconds: completedDuration,
            taskTitle: taskTitle
        )

        if completedPhase == .focus {
            completedFocusRounds += 1
            phase = completedFocusRounds.isMultiple(of: 4) ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }

        deadline = nil
        pausedSeconds = durationSeconds(for: phase)
        startedAt = nil
        status = .finished
        persist()
        return completion
    }

    func reset() {
        status = .idle
        phase = .focus
        deadline = nil
        pausedSeconds = 0
        startedAt = nil
        persist()
    }

    private func durationSeconds(for phase: FocusTimerPhase) -> Int {
        let minutes = phase == .focus ? selectedMinutes : phase.durationMinutes
        return minutes * 60
    }

    private func restore() {
        guard
            let data = storage.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }

        status = snapshot.status
        selectedMinutes = snapshot.selectedMinutes
        deadline = snapshot.deadline
        pausedSeconds = snapshot.pausedSeconds
        startedAt = snapshot.startedAt
        taskTitle = snapshot.taskTitle
        phase = snapshot.phase ?? .focus
        completedFocusRounds = snapshot.completedFocusRounds ?? 0

        if status == .finished, pausedSeconds == 0 {
            pausedSeconds = durationSeconds(for: phase)
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            status: status,
            selectedMinutes: selectedMinutes,
            deadline: deadline,
            pausedSeconds: pausedSeconds,
            startedAt: startedAt,
            taskTitle: taskTitle,
            phase: phase,
            completedFocusRounds: completedFocusRounds
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        storage.set(data, forKey: storageKey)
    }
}
