//
//  SettingsView.swift
//  FocusLog
//

import SwiftUI
import UIKit
import UserNotifications

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SettingsView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.settingsPath) {
            List {
                Section("Preferences") {
                    NavigationLink(value: AppRoute.appearance) {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    NavigationLink(value: AppRoute.notifications) {
                        Label("Notifications", systemImage: "bell.badge")
                    }
                }

                Section("About") {
                    NavigationLink(value: AppRoute.about) {
                        Label("About FocusLog", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: AppRoute.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .appearance:
            AppearanceSettingsView()
        case .notifications:
            NotificationSettingsView()
        case .about:
            AboutView()
        default:
            EmptyView()
        }
    }
}

private struct AppearanceSettingsView: View {
    @AppStorage("appAppearance") private var appearanceRawValue = AppAppearance.system.rawValue

    private var appearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRawValue) ?? .system },
            set: { appearanceRawValue = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.inline)
            } footer: {
                Text("System follows your device setting. Light and Dark override it while FocusLog is open.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationSettingsView: View {
    @State private var status = "Checking permission…"

    var body: some View {
        Form {
            Section("Task reminders") {
                LabeledContent("Permission", value: status)
                Text("FocusLog schedules a reminder only when an unfinished task has a future due time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Open Notification Settings") {
                    guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatus() }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        status = switch settings.authorizationStatus {
        case .authorized: "Allowed"
        case .provisional: "Provisional"
        case .ephemeral: "Temporary"
        case .denied: "Not allowed"
        case .notDetermined: "Not requested"
        @unknown default: "Unknown"
        }
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Minimum iOS", value: "17.0")
            }
            Section("Privacy") {
                Text("FocusLog stores tasks, sessions, and preferences only on this device. No account or server is required.")
            }
            Section("Built with") {
                Text("SwiftUI · SwiftData · Charts · UserNotifications")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(AppRouter())
}
