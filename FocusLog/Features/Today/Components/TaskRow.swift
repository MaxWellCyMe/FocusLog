//
//  TaskRow.swift
//  FocusLog
//

import SwiftUI

struct TaskRow: View {
    @Bindable var task: FocusTask

    var onToggle: () -> Void

    private var category: TaskCategory {
        TaskCategory(rawValue: task.categoryRawValue) ?? .work
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary.opacity(0.65))
                    .frame(width: 28, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark \(task.title) as active" : "Mark \(task.title) as done")

            VStack(alignment: .leading, spacing: 7) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, pattern: .solid, color: .secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(category.rawValue, systemImage: category.symbol)
                        .foregroundStyle(category.color)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Label("\(task.estimatedMinutes) min", systemImage: "clock")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 11, weight: .medium))
            }

            Spacer(minLength: 4)

            if let dueDate = task.dueDate {
                Text(dueDate, format: .dateTime.hour().minute())
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 76)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
