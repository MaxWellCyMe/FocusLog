//
//  TaskDetailView.swift
//  FocusLog
//

import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var task: FocusTask

    @State private var isShowingEditor = false
    @State private var isShowingDeleteConfirmation = false

    private var category: TaskCategory {
        TaskCategory(rawValue: task.categoryRawValue) ?? .work
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: category.symbol)
                            .foregroundStyle(category.color)
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(category.color)
                    }

                    Text(task.title)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                    Label(task.isCompleted ? "Completed" : "In progress", systemImage: task.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Plan") {
                LabeledContent("Estimated focus") {
                    Text("\(task.estimatedMinutes) minutes")
                }
                if let dueDate = task.dueDate {
                    LabeledContent("Due") {
                        Text(dueDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    LabeledContent("Due", value: "No due time")
                }
                LabeledContent("Created") {
                    Text(task.createdAt, format: .dateTime.month(.abbreviated).day().year())
                }
            }

            Section {
                Button {
                    task.isCompleted.toggle()
                    task.completedAt = task.isCompleted ? .now : nil
                    Task { await TaskReminderService.synchronizeReminder(for: task) }
                } label: {
                    Label(
                        task.isCompleted ? "Mark as active" : "Mark as completed",
                        systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                    )
                }
            }

            Section {
                Button("Delete task", systemImage: "trash", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Task details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isShowingEditor = true }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            TaskEditorView(task: task)
        }
        .confirmationDialog("Delete this task?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete task", role: .destructive, action: deleteTask)
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func deleteTask() {
        Task { await TaskReminderService.cancelReminder(for: task) }
        modelContext.delete(task)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: FocusTask(title: "Prepare product demo", estimatedMinutes: 45))
    }
    .modelContainer(for: [FocusTask.self, FocusSession.self], inMemory: true)
}
