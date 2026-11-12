//
//  TodayView.swift
//  FocusLog
//

import SwiftData
import SwiftUI

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Done"

    var id: String { rawValue }
}

enum TaskScope: String, CaseIterable, Identifiable {
    case today = "Today"
    case upcoming = "Upcoming"
    case overdue = "Overdue"

    var id: String { rawValue }
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \FocusTask.createdAt, order: .reverse) private var tasks: [FocusTask]

    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedScope: TaskScope = .today
    @State private var taskToEdit: FocusTask?
    @State private var isShowingComposer = false

    private var completedCount: Int {
        scopedTasks.filter(\.isCompleted).count
    }

    private var scopedTasks: [FocusTask] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? .distantFuture

        switch selectedScope {
        case .today:
            return tasks.filter { task in
                if task.isCompleted {
                    return task.completedAt.map(calendar.isDateInToday) ?? calendar.isDateInToday(task.createdAt)
                }
                return task.dueDate.map(calendar.isDateInToday) ?? calendar.isDateInToday(task.createdAt)
            }
        case .upcoming:
            return tasks.filter { task in
                !task.isCompleted && (task.dueDate ?? .distantPast) >= startOfTomorrow
            }
        case .overdue:
            return tasks.filter { task in
                !task.isCompleted && (task.dueDate ?? .distantFuture) < startOfToday
            }
        }
    }

    private var visibleTasks: [FocusTask] {
        switch selectedFilter {
        case .all: scopedTasks
        case .active: scopedTasks.filter { !$0.isCompleted }
        case .completed: scopedTasks.filter(\.isCompleted)
        }
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.todayPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    TodayProgressCard(completedCount: completedCount, totalCount: scopedTasks.count)
                    taskSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                addTaskBar
            }
            .sheet(isPresented: $isShowingComposer, onDismiss: { taskToEdit = nil }) {
                TaskEditorView(task: taskToEdit)
            }
            .navigationDestination(for: AppRoute.self, destination: destination)
        }
        .tint(Color.indigo)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Text("Today")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.indigo)
                .frame(width: 44, height: 44)
                .background(Color.indigo.opacity(0.10), in: Circle())
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your tasks")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Spacer()
                Text("\(visibleTasks.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Picker("Task filter", selection: $selectedFilter) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            TaskScopePicker(selection: $selectedScope)

            if visibleTasks.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(visibleTasks) { task in
                        TaskRow(task: task) {
                            toggleCompletion(for: task)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { router.showTask(task) }
                        .contextMenu {
                            Button("Edit task", systemImage: "pencil") { edit(task) }
                            Button(task.isCompleted ? "Mark as active" : "Mark as done", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark") {
                                toggleCompletion(for: task)
                            }
                            Divider()
                            Button("Delete task", systemImage: "trash", role: .destructive) {
                                Task { await TaskReminderService.cancelReminder(for: task) }
                                modelContext.delete(task)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: selectedFilter == .completed ? "checkmark.circle" : "list.bullet.clipboard")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.indigo.opacity(0.75))
            Text(emptyTitle)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Text(emptyMessage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .all: "A clear slate"
        case .active: "All caught up"
        case .completed: "Nothing completed yet"
        }
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .all: "Add your first task and make room for focused work."
        case .active: "There are no active tasks right now."
        case .completed: "Completed tasks will show up here."
        }
    }

    private var addTaskBar: some View {
        Button {
            taskToEdit = nil
            isShowingComposer = true
        } label: {
            Label("New task", systemImage: "plus")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(Color.indigo, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func edit(_ task: FocusTask) {
        taskToEdit = task
        isShowingComposer = true
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .taskDetail(let identifier):
            if let task = tasks.first(where: { $0.persistentModelID == identifier }) {
                TaskDetailView(task: task)
            } else {
                ContentUnavailableView("Task not found", systemImage: "exclamationmark.triangle")
            }
        default:
            EmptyView()
        }
    }

    private func toggleCompletion(for task: FocusTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
        Task { await TaskReminderService.synchronizeReminder(for: task) }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [FocusTask.self, FocusSession.self], inMemory: true)
}
