//
//  FocusSession.swift
//  FocusLog
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var startedAt: Date
    var completedAt: Date
    var durationSeconds: Int
    var taskTitle: String?

    init(startedAt: Date, completedAt: Date = .now, durationSeconds: Int, taskTitle: String? = nil) {
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.taskTitle = taskTitle
    }
}
