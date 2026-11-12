//
//  AppRouter.swift
//  FocusLog
//

import Foundation
import Observation
import SwiftData

enum AppTab: String, Hashable {
    case today
    case focus
    case insights
    case settings
}

enum AppRoute: Hashable {
    case taskDetail(PersistentIdentifier)
    case sessionHistory
    case appearance
    case notifications
    case about
}

@Observable
final class AppRouter {
    var selectedTab: AppTab
    var todayPath: [AppRoute] = []
    var insightsPath: [AppRoute] = []
    var settingsPath: [AppRoute] = []

    init() {
        selectedTab = AppTab(rawValue: UserDefaults.standard.string(forKey: "selectedTab") ?? "") ?? .today
    }

    func showTask(_ task: FocusTask) {
        selectedTab = .today
        todayPath.append(.taskDetail(task.persistentModelID))
    }

    func showSessionHistory() {
        selectedTab = .insights
        insightsPath.append(.sessionHistory)
    }
}
