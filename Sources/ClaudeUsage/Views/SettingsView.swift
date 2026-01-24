import SwiftUI

struct SettingsView: View {
    @Bindable var settingsService: SettingsService
    @Bindable var notificationService: NotificationService

    var body: some View {
        TabView {
            GeneralSettingsTab(settingsService: settingsService)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AlertsSettingsTab(notificationService: notificationService)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 350, height: 280)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @Bindable var settingsService: SettingsService

    var body: some View {
        Form {
            Section {
                Picker("Menubar Display", selection: $settingsService.menubarDisplay) {
                    ForEach(MenubarDisplay.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)

                Text("Choose what percentage to display in the menubar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Menubar", systemImage: "menubar.rectangle")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Alerts Tab

struct AlertsSettingsTab: View {
    @Bindable var notificationService: NotificationService

    var body: some View {
        Form {
            Section {
                Toggle("Enable Alerts", isOn: $notificationService.alertsEnabled)

                if notificationService.alertsEnabled {
                    Toggle("5-Hour Usage (80%, 90%)", isOn: $notificationService.fiveHourAlerts)
                        .padding(.leading, 8)

                    Toggle("7-Day Usage (80%, 90%)", isOn: $notificationService.sevenDayAlerts)
                        .padding(.leading, 8)
                }
            } header: {
                Label("Notifications", systemImage: "bell.fill")
            }

            Section {
                Text("Alerts trigger when usage crosses 80% or 90% thresholds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Claude Usage")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 4) {
                Text("Made by")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Common Tools Co.")
                    .font(.headline)
            }

            Link(destination: URL(string: "https://github.com/wrnsnng/claude-usage")!) {
                Label("View on GitHub", systemImage: "link")
                    .font(.caption)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView(
        settingsService: SettingsService(),
        notificationService: NotificationService()
    )
}
