//
//  TaskReminderService.swift
//  FocusLog
//

import Foundation
import UserNotifications

enum TaskReminderService {
    private static let center = UNUserNotificationCenter.current()

    static func synchronizeReminder(for task: FocusTask) async {
        let identifier = reminderIdentifier(for: task)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard
            !task.isCompleted,
            let dueDate = task.dueDate,
            dueDate > .now,
            await isAuthorized()
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to focus"
        content.body = task.title
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.calendar, .timeZone, .year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await center.add(request)
    }

    static func cancelReminder(for task: FocusTask) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: task)])
    }

    private static func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func reminderIdentifier(for task: FocusTask) -> String {
        "focuslog.task-reminder.\(task.createdAt.timeIntervalSinceReferenceDate)"
    }
}
