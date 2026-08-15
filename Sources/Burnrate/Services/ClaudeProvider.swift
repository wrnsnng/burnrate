import Foundation
import SwiftUI

final class ClaudeProvider: LLMProvider {
    let info = ProviderInfo(
        id: "claude",
        name: "Claude Code",
        icon: "message.fill",
        brandColor: 0xDA7756,
        unavailableMessage: "Claude Code not detected. Sign in with claude login."
    )

    var isInstalled: Bool {
        !KeychainService.isTokenExpired()
    }

    func fetchUsage() -> ProviderUsage? {
        // The ViewModel fetches UsageLimits via UsageAPIClient (async actor)
        // and maps them to ProviderUsage directly. This provider only
        // supplies metadata and isInstalled.
        nil
    }

    /// Maps Claude-specific UsageLimits to the unified ProviderUsage format.
    static func mapUsage(_ limits: UsageLimits) -> ProviderUsage {
        var extra: [String: String]? = nil
        if limits.opusUtilization > 0 {
            extra = ["Opus": "\(Int(limits.opusUtilization * 100))%"]
        }

        return ProviderUsage(
            primaryUtilization: limits.fiveHourUtilization,
            primaryLabel: "5-Hour",
            primaryResetsAt: limits.fiveHourResetsAt,
            secondaryUtilization: limits.sevenDayUtilization,
            secondaryLabel: "7-Day",
            secondaryResetsAt: limits.sevenDayResetsAt,
            extraInfo: extra
        )
    }
}
