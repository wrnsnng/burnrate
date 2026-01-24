import SwiftUI

struct AlertSettingsView: View {
    @Bindable var notificationService: NotificationService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Alerts", systemImage: "bell.fill")
                .font(.headline)

            Toggle("Enable alerts", isOn: $notificationService.alertsEnabled)
                .toggleStyle(.switch)

            if notificationService.alertsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("5-hour usage (80%, 90%)", isOn: $notificationService.fiveHourAlerts)
                        .toggleStyle(.switch)
                        .padding(.leading, 8)

                    Toggle("7-day usage (80%, 90%)", isOn: $notificationService.sevenDayAlerts)
                        .toggleStyle(.switch)
                        .padding(.leading, 8)
                }
                .font(.subheadline)
            }
        }
    }
}

#Preview {
    AlertSettingsView(notificationService: NotificationService())
        .padding()
        .frame(width: 300)
}
