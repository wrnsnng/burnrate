import Foundation

struct AccountParser {
    private let configPath: URL

    init() {
        self.configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude.json")
    }

    func getAccountInfo() -> AccountInfo {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: configPath)
            let config = try JSONDecoder().decode(ClaudeConfig.self, from: data)

            return AccountInfo(
                hasExtraUsageEnabled: config.oauthAccount?.hasExtraUsageEnabled ?? false,
                billingType: config.oauthAccount?.organizationBillingType ?? "unknown",
                email: config.oauthAccount?.emailAddress
            )
        } catch {
            return .empty
        }
    }
}

private struct ClaudeConfig: Codable {
    let oauthAccount: OAuthAccount?
}

private struct OAuthAccount: Codable {
    let hasExtraUsageEnabled: Bool?
    let organizationBillingType: String?
    let emailAddress: String?
}
