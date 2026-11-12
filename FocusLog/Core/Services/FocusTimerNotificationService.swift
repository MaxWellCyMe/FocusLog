//
//  FocusTimerNotificationService.swift
//  FocusLog
//

import Foundation
import UserNotifications

enum FocusTimerNotificationService {
    private static let identifier = "focuslog.timer-completion"
    private static let center = UNUserNotificationCenter.current()

    static func synchronize(for timer: FocusTimerController) async {
        cancel()

        guard
            timer.status == .running,
            let deadline = timer.deadline,
            deadline > .now,
            await isAuthorized()
        else { return }

        let content = UNMutableNotificationContent()
        content.title = timer.phase == .focus ? "Focus session complete" : "Break complete"
        content.body = timer.phase == .focus
            ? "Nice work. Your \(nextPhase(after: timer).title.lowercased()) is ready."
            : "Ready for another focused session?"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: deadline.timeIntervalSinceNow,
                repeats: false
            )
        )
        try? await center.add(request)
    }

    static func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private static func nextPhase(after timer: FocusTimerController) -> FocusTimerPhase {
        let nextRound = timer.completedFocusRounds + 1
        return nextRound.isMultiple(of: 4) ? .longBreak : .shortBreak
    }

    private static func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}
