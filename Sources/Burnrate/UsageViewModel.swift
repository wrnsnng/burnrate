import AppKit
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
        case .iconOnly, .chart:
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
        case .both, .iconOnly, .chart:
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

    var menubarIcon: NSImage? {
        guard let limits = usageLimits else {
            return MenubarIconRenderer.render(
                fiveHour: 0,
                sevenDay: 0,
                colorScheme: settingsService.menubarColorScheme
            )
        }

        return MenubarIconRenderer.render(
            fiveHour: limits.fiveHourUtilization,
            sevenDay: limits.sevenDayUtilization,
            colorScheme: settingsService.menubarColorScheme
        )
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

                // Surface API/auth errors to UI
                if limits == nil {
                    if self.isTokenExpired {
                        self.errorMessage = "Please log in: run 'claude' to authenticate"
                    } else {
                        self.errorMessage = "Unable to reach Anthropic API"
                    }
                }

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
        runInTerminal("cd \"\(session.projectPath)\" && claude --resume \(session.id)")
    }

    func openActiveSession() {
        guard let session = currentSession else { return }
        if focusRunningClaudeTerminal() { return }
        runInTerminal("cd \"\(session.projectPath)\" && claude --resume \(session.sessionId)")
    }

    func openClaude() {
        runInTerminal("claude")
    }

    // MARK: - Terminal Helpers

    private func runInTerminal(_ cmd: String) {
        let escapedCmd = cmd
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        switch settingsService.preferredTerminal {
        case .terminal:
            let script = "tell application \"Terminal\" to do script \"\(escapedCmd)\""
            runAppleScript(script)

        case .iterm2:
            let script = """
            tell application "iTerm2"
                create window with default profile command "\(escapedCmd)"
            end tell
            """
            runAppleScript(script)

        case .warp:
            // Warp supports a URL scheme for running commands
            let encoded = cmd.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "warp://action/new_tab?command=\(encoded)") {
                NSWorkspace.shared.open(url)
            } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "dev.warp.Warp-Stable") {
                NSWorkspace.shared.open(appURL)
            }

        case .ghostty:
            // Ghostty accepts --command via CLI args
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Ghostty", "--args", "--command=bash", "-c", cmd]
            try? process.run()
        }
    }

    private func runAppleScript(_ source: String) {
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                NSLog("[Burnrate] AppleScript error: \(error)")
            }
        }
    }

    /// Tries to find and focus an already-running terminal that has a `claude` process.
    /// Returns true if a terminal was successfully focused.
    @discardableResult
    private func focusRunningClaudeTerminal() -> Bool {
        // Find claude PIDs via `ps aux`
        let psProcess = Process()
        psProcess.executableURL = URL(fileURLWithPath: "/bin/ps")
        psProcess.arguments = ["aux"]
        let psPipe = Pipe()
        psProcess.standardOutput = psPipe
        psProcess.standardError = FileHandle.nullDevice

        do {
            try psProcess.run()
            psProcess.waitUntilExit()
        } catch {
            return false
        }

        let psData = psPipe.fileHandleForReading.readDataToEndOfFile()
        guard let psOutput = String(data: psData, encoding: .utf8) else { return false }

        // Find lines where the command column contains "claude" (but not this app or grep)
        let claudeLine = psOutput.split(separator: "\n").first { line in
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count > 10 else { return false }
            let cmdPart = parts[10...].joined(separator: " ")
            return cmdPart.contains("claude") && !cmdPart.contains("Burnrate") && !cmdPart.contains("grep")
        }
        guard let claudeLine = claudeLine else { return false }

        let parts = claudeLine.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count > 1, let claudePid = Int32(parts[1]) else { return false }

        // Get parent PID
        let ppidProcess = Process()
        ppidProcess.executableURL = URL(fileURLWithPath: "/bin/ps")
        ppidProcess.arguments = ["-o", "ppid=", "-p", "\(claudePid)"]
        let ppidPipe = Pipe()
        ppidProcess.standardOutput = ppidPipe
        ppidProcess.standardError = FileHandle.nullDevice

        do {
            try ppidProcess.run()
            ppidProcess.waitUntilExit()
        } catch {
            return false
        }

        let ppidData = ppidPipe.fileHandleForReading.readDataToEndOfFile()
        guard let ppidString = String(data: ppidData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let ppid = Int32(ppidString) else { return false }

        // Activate the parent process (the terminal)
        if let app = NSRunningApplication(processIdentifier: ppid) {
            app.activate()
            return true
        }

        return false
    }
}
