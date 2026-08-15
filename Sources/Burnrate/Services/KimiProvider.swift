import Foundation
import SwiftUI

final class KimiProvider: LLMProvider {
    let info = ProviderInfo(
        id: "kimi",
        name: "Kimi K2.5",
        icon: "sparkles",
        brandColor: 0x6366F1,
        unavailableMessage: "Install Kimi CLI to track usage",
        installCommand: "npm install -g @anthropic/kimi-cli"
    )

    private var kimiHome: String {
        if let custom = ProcessInfo.processInfo.environment["KIMI_SHARE_DIR"] {
            return custom
        }
        return NSHomeDirectory() + "/.kimi"
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: kimiHome)
    }

    func fetchUsage() -> ProviderUsage? {
        // Kimi CLI does not expose rate-limit data in local session files yet.
        // Usage tracking will be added when the CLI surfaces this data.
        nil
    }
}
