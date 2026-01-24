import Foundation
import SwiftUI

@Observable
final class UsageViewModel {
    var currentSession: CurrentSession?
    var usageLimits: UsageLimits?
    var accountInfo: AccountInfo = .empty
    var recentSessions: [SessionInfo] = []
    var isTokenExpired: Bool = true
    var errorMessage: String?
    var isLoading: Bool = false

    // Analytics data
    var snapshots: [UsageSnapshot] = []
    var todayStats: DailyStats = .empty
    var weekStats: (tokens: Int, sessions: Int, cost: Double) = (0, 0, 0)

    // Services
    let notificationService = NotificationService()
    let settingsService = SettingsService()
    private let sessionParser = SessionParser()
    private let accountParser = AccountParser()
    private let usageAPI = UsageAPIClient()
    private let analyticsStore = AnalyticsStore()
    private var refreshTimer: Timer?

    // Track previous values for threshold detection
    private var previousFiveHour: Double?
    private var previousSevenDay: Double?

    var menubarTitle: String {
        guard let limits = usageLimits else {
            return isTokenExpired ? "!" : "--"
        }

        switch settingsService.menubarDisplay {
        case .sevenDay:
            return "\(Int(limits.sevenDayUtilization.rounded()))%"
        case .fiveHour:
            return "\(Int(limits.fiveHourUtilization.rounded()))%"
        case .both:
            return "\(Int(limits.fiveHourUtilization.rounded()))|\(Int(limits.sevenDayUtilization.rounded()))"
        case .iconOnly:
            return ""
        }
    }

    var menubarEmoji: String {
        guard let limits = usageLimits else {
            return "🤖"
        }

        // Use the displayed metric, or max of both if showing "both" or "icon only"
        let percentage: Double
        switch settingsService.menubarDisplay {
        case .sevenDay:
            percentage = limits.sevenDayUtilization
        case .fiveHour:
            percentage = limits.fiveHourUtilization
        case .both, .iconOnly:
            percentage = max(limits.fiveHourUtilization, limits.sevenDayUtilization)
        }

        if percentage >= 90 {
            return "🚨"
        } else if percentage >= 70 {
            return "🔥"
        } else {
            return "🤖"
        }
    }

    func startAutoRefresh() {
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        isLoading = true
        errorMessage = nil

        // Get session data
        self.recentSessions = sessionParser.getRecentSessions()
        self.currentSession = sessionParser.getCurrentSession()
        self.accountInfo = accountParser.getAccountInfo()
        self.isTokenExpired = KeychainService.isTokenExpired()

        // Calculate today's token usage from sessions
        let todayTokens = calculateTodayTokens()
        let todaySessions = countTodaySessions()

        // Fetch API data and analytics asynchronously
        Task {
            let limits = await usageAPI.fetchUsage()

            // Record analytics
            if let limits = limits {
                await analyticsStore.recordSnapshot(
                    fiveHour: limits.fiveHourUtilization,
                    sevenDay: limits.sevenDayUtilization,
                    opus: limits.opusUtilization
                )

                await analyticsStore.recordDailyStats(tokens: todayTokens, sessions: todaySessions)
            }

            // Load analytics data
            let allSnapshots = await analyticsStore.getAllSnapshots()
            let today = await analyticsStore.getTodayStats()
            let week = await analyticsStore.getWeekStats()

            await MainActor.run {
                self.usageLimits = limits
                self.snapshots = allSnapshots
                self.todayStats = today
                self.weekStats = week
                self.isLoading = false

                // Check for alerts
                if let limits = limits {
                    self.notificationService.checkAndNotify(
                        fiveHour: limits.fiveHourUtilization,
                        sevenDay: limits.sevenDayUtilization,
                        previousFiveHour: self.previousFiveHour,
                        previousSevenDay: self.previousSevenDay
                    )

                    self.previousFiveHour = limits.fiveHourUtilization
                    self.previousSevenDay = limits.sevenDayUtilization
                }
            }
        }
    }

    private func calculateTodayTokens() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return recentSessions
            .filter { calendar.startOfDay(for: $0.timestamp) == today }
            .reduce(0) { $0 + $1.totalTokens }
    }

    private func countTodaySessions() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return recentSessions
            .filter { calendar.startOfDay(for: $0.timestamp) == today }
            .count
    }

    func openSession(_ session: SessionInfo) {
        let cmd = "cd \"\(session.projectPath)\" && claude --resume \(session.id)"
        let script = "tell application \"Terminal\" to do script \"\(cmd)\""

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    func openClaude() {
        let script = "tell application \"Terminal\" to do script \"claude\""
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
