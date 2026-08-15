import Foundation
import SwiftUI

final class GeminiProvider: LLMProvider {
    let info = ProviderInfo(
        id: "gemini",
        name: "Gemini CLI",
        icon: "wand.and.stars",
        brandColor: 0x4285F4,
        unavailableMessage: "Install Gemini CLI to track usage",
        installCommand: "npm install -g @anthropic/gemini-cli"
    )

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: NSHomeDirectory() + "/.gemini")
    }

    func fetchUsage() -> ProviderUsage? {
        // Gemini CLI usage stats are only available via the /stats command.
        // Local file parsing for rate-limit data will be added when supported.
        nil
    }
}
