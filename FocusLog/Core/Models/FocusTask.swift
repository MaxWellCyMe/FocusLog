//
//  FocusTask.swift
//  FocusLog
//

import SwiftData
import SwiftUI

enum TaskCategory: String, CaseIterable, Identifiable {
    case work = "Work"
    case study = "Study"
    case personal = "Personal"
    case health = "Health"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .work: "briefcase.fill"
        case .study: "book.fill"
        case .personal: "person.fill"
        case .health: "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: .indigo
        case .study: .orange
        case .personal: .teal
        case .health: .pink
        }
    }
}

@Model
final class FocusTask {
    var title: String
    var categoryRawValue: String
    var estimatedMinutes: Int
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date

    init(
        title: String,
        categoryRawValue: String = TaskCategory.work.rawValue,
        estimatedMinutes: Int = 25,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.title = title
        self.categoryRawValue = categoryRawValue
        self.estimatedMinutes = estimatedMinutes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}
