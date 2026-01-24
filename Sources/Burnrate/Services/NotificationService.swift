import Foundation
import UserNotifications

enum AlertType: String {
    case fiveHour80 = "5-hour usage at 80%"
    case fiveHour90 = "5-hour usage at 90%"
    case sevenDay80 = "7-day usage at 80%"
    case sevenDay90 = "7-day usage at 90%"
    case dailySummary = "Daily summary"
}

@Observable
final class NotificationService {
    var alertsEnabled: Bool {
        didSet { UserDefaults.standard.set(alertsEnabled, forKey: "alertsEnabled") }
    }

    var fiveHourAlerts: Bool {
        didSet { UserDefaults.standard.set(fiveHourAlerts, forKey: "fiveHourAlerts") }
    }

    var sevenDayAlerts: Bool {
        didSet { UserDefaults.standard.set(sevenDayAlerts, forKey: "sevenDayAlerts") }
    }

    private var lastAlertsSent: [AlertType: Date] = [:]
    private let alertCooldown: TimeInterval = 3600 // 1 hour between same alerts

    init() {
        self.alertsEnabled = UserDefaults.standard.object(forKey: "alertsEnabled") as? Bool ?? true
        self.fiveHourAlerts = UserDefaults.standard.object(forKey: "fiveHourAlerts") as? Bool ?? true
        self.sevenDayAlerts = UserDefaults.standard.object(forKey: "sevenDayAlerts") as? Bool ?? true
    }

    func requestPermissions() {
        // Only request if we're running as a bundled app
        guard Bundle.main.bundleIdentifier != nil else {
            NSLog("[Notifications] Skipping permission request - not a bundled app")
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                NSLog("[Notifications] Permission error: \(error)")
            } else {
                NSLog("[Notifications] Permission granted: \(granted)")
            }
        }
    }

    func checkAndNotify(fiveHour: Double, sevenDay: Double, previousFiveHour: Double?, previousSevenDay: Double?) {
        guard alertsEnabled else { return }

        // Check 5-hour thresholds
        if fiveHourAlerts {
            if fiveHour >= 90 && (previousFiveHour ?? 0) < 90 {
                sendAlert(.fiveHour90, percentage: fiveHour)
            } else if fiveHour >= 80 && (previousFiveHour ?? 0) < 80 {
                sendAlert(.fiveHour80, percentage: fiveHour)
            }
        }

        // Check 7-day thresholds
        if sevenDayAlerts {
            if sevenDay >= 90 && (previousSevenDay ?? 0) < 90 {
                sendAlert(.sevenDay90, percentage: sevenDay)
            } else if sevenDay >= 80 && (previousSevenDay ?? 0) < 80 {
                sendAlert(.sevenDay80, percentage: sevenDay)
            }
        }
    }

    func sendDailySummary(fiveHour: Double, sevenDay: Double, tokensToday: Int, sessionsToday: Int) {
        guard alertsEnabled else { return }

        // Only send if we're running as a bundled app
        guard Bundle.main.bundleIdentifier != nil else {
            NSLog("[Notifications] Would send daily summary")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Burnrate daily summary"
        content.body = """
            5-Hour: \(Int(fiveHour))% | 7-Day: \(Int(sevenDay))%
            Today: \(formatTokens(tokensToday)) tokens, \(sessionsToday) sessions
            """
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily-summary-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func sendAlert(_ type: AlertType, percentage: Double) {
        // Only send if we're running as a bundled app
        guard Bundle.main.bundleIdentifier != nil else {
            NSLog("[Notifications] Would alert: \(type.rawValue) at \(Int(percentage))%")
            return
        }

        // Check cooldown
        if let lastSent = lastAlertsSent[type],
           Date().timeIntervalSince(lastSent) < alertCooldown {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Burnrate alert"
        content.body = "\(type.rawValue) - currently at \(Int(percentage))%"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("[Notifications] Failed to send: \(error)")
            } else {
                NSLog("[Notifications] Sent alert: \(type.rawValue)")
            }
        }

        lastAlertsSent[type] = Date()
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
