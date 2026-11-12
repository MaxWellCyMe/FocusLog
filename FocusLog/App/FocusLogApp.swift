//
//  FocusLogApp.swift
//  FocusLog
//
//  Created by 钟达 on 2026/11/12.
//

import SwiftUI
import SwiftData

@main
struct FocusLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [FocusTask.self, FocusSession.self])
    }
}
