//
//  RootTabView.swift
//  FocusLog
//

import SwiftData
import SwiftUI

struct RootTabView: View {
    @State private var router = AppRouter()
    @AppStorage("appAppearance") private var appearanceRawValue = AppAppearance.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        (AppAppearance(rawValue: appearanceRawValue) ?? .system).colorScheme
    }

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checklist")
                }
                .tag(AppTab.today)

            FocusTimerView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
                .tag(AppTab.focus)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
                .tag(AppTab.insights)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(Color.indigo)
        .preferredColorScheme(preferredColorScheme)
        .environment(router)
        .onChange(of: router.selectedTab) { _, selectedTab in
            UserDefaults.standard.set(selectedTab.rawValue, forKey: "selectedTab")
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [FocusTask.self, FocusSession.self], inMemory: true)
}
