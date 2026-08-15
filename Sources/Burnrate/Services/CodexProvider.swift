import Foundation
import SwiftUI

final class CodexProvider: LLMProvider {
    let info = ProviderInfo(
        id: "codex",
        name: "Codex CLI",
        icon: "terminal.fill",
        brandColor: 0x10A37F,
        unavailableMessage: "Codex CLI not detected. Install from openai.com."
    )

    var isInstalled: Bool {
        CodexSessionParser().isCodexInstalled
    }

    func fetchUsage() -> ProviderUsage? {
        guard let limits = CodexSessionParser().getUsageLimits() else {
            return nil
        }
        return Self.mapUsage(limits)
    }

    /// Maps Codex-specific CodexUsageLimits to the unified ProviderUsage format.
    static func mapUsage(_ limits: CodexUsageLimits) -> ProviderUsage {
        var extra: [String: String]? = nil
        var tokenParts: [String] = []
        if let input = limits.inputTokens {
            tokenParts.append("In: \(formatTokenCount(input))")
        }
        if let output = limits.outputTokens {
            tokenParts.append("Out: \(formatTokenCount(output))")
        }
        if let reasoning = limits.reasoningTokens {
            tokenParts.append("Reasoning: \(formatTokenCount(reasoning))")
        }
        if !tokenParts.isEmpty {
            extra = ["Tokens": tokenParts.joined(separator: ", ")]
        }

        return ProviderUsage(
            primaryUtilization: limits.fiveHourUtilization,
            primaryLabel: "5-Hour",
            primaryResetsAt: limits.fiveHourResetsAt,
            secondaryUtilization: limits.weeklyUtilization,
            secondaryLabel: "Weekly",
            secondaryResetsAt: limits.weeklyResetsAt,
            extraInfo: extra
        )
    }

    private static func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
