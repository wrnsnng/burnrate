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

    private let sessionParser = SessionParser()
    private let accountParser = AccountParser()
    private let usageAPI = UsageAPIClient()
    private var refreshTimer: Timer?

    var menubarTitle: String {
        if let limits = usageLimits {
            return "\(Int(limits.sevenDayUtilization.rounded()))%"
        } else if isTokenExpired {
            return "!"
        }
        return "--"
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
        NSLog("[DEBUG] refresh() called")
        isLoading = true
        errorMessage = nil

        NSLog("[DEBUG] Getting recent sessions...")
        self.recentSessions = sessionParser.getRecentSessions()
        NSLog("[DEBUG] Got \(recentSessions.count) sessions")

        NSLog("[DEBUG] Getting current session...")
        self.currentSession = sessionParser.getCurrentSession()
        NSLog("[DEBUG] Current session: \(currentSession?.slug ?? "none")")

        NSLog("[DEBUG] Getting account info...")
        self.accountInfo = accountParser.getAccountInfo()
        NSLog("[DEBUG] Account: \(accountInfo.email ?? "no email")")

        NSLog("[DEBUG] Checking token...")
        self.isTokenExpired = KeychainService.isTokenExpired()
        NSLog("[DEBUG] Token expired: \(isTokenExpired)")

        // Fetch API data asynchronously
        NSLog("[DEBUG] Starting API fetch...")
        Task {
            let limits = await usageAPI.fetchUsage()
            await MainActor.run {
                self.usageLimits = limits
                self.isLoading = false
                NSLog("[DEBUG] Got limits: \(limits?.sevenDayUtilization ?? -1)")
            }
        }
        NSLog("[DEBUG] refresh() returning")
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
