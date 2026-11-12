//
//  TaskEditorView.swift
//  FocusLog
//

import SwiftData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let task: FocusTask?

    @State private var title: String
    @State private var category: TaskCategory
    @State private var estimatedMinutes: Int
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(task: FocusTask?) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _category = State(initialValue: TaskCategory(rawValue: task?.categoryRawValue ?? "Work") ?? .work)
        _estimatedMinutes = State(initialValue: task?.estimatedMinutes ?? 25)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now)
    }

    private var normalizedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs your focus?", text: $title, axis: .vertical)
                        .lineLimit(1...3)

                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbol).tag(category)
                        }
                    }
                }

                Section("Plan") {
                    Picker("Estimated time", selection: $estimatedMinutes) {
                        ForEach([15, 25, 30, 45, 60, 90], id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }

                    Toggle("Add a due time", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(task == nil ? "New task" : "Edit task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(normalizedTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let taskToSynchronize: FocusTask

        if let task {
            task.title = normalizedTitle
            task.categoryRawValue = category.rawValue
            task.estimatedMinutes = estimatedMinutes
            task.dueDate = hasDueDate ? dueDate : nil
            taskToSynchronize = task
        } else {
            let newTask = FocusTask(
                title: normalizedTitle,
                categoryRawValue: category.rawValue,
                estimatedMinutes: estimatedMinutes,
                dueDate: hasDueDate ? dueDate : nil
            )
            modelContext.insert(newTask)
            taskToSynchronize = newTask
        }
        try? modelContext.save()
        Task { await TaskReminderService.synchronizeReminder(for: taskToSynchronize) }
        dismiss()
    }
}
