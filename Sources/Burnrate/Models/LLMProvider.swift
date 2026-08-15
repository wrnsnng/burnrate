import Foundation
import SwiftUI

// MARK: - Provider Usage (unified usage data for any LLM provider)

struct ProviderUsage {
    let primaryUtilization: Double
    let primaryLabel: String
    let primaryResetsAt: Date?

    let secondaryUtilization: Double?
    let secondaryLabel: String?
    let secondaryResetsAt: Date?

    /// Provider-specific extra data (e.g. Opus usage, token counts)
    let extraInfo: [String: String]?

    static let empty = ProviderUsage(
        primaryUtilization: 0,
        primaryLabel: "Usage",
        primaryResetsAt: nil,
        secondaryUtilization: nil,
        secondaryLabel: nil,
        secondaryResetsAt: nil,
        extraInfo: nil
    )
}

// MARK: - Provider Metadata

struct ProviderInfo {
    let id: String
    let name: String
    let icon: String        // SF Symbol name
    let brandColor: UInt    // Hex color
    let unavailableMessage: String
    let installCommand: String?

    var color: Color {
        Color(hex: brandColor)
    }

    init(id: String, name: String, icon: String, brandColor: UInt, unavailableMessage: String, installCommand: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.brandColor = brandColor
        self.unavailableMessage = unavailableMessage
        self.installCommand = installCommand
    }
}

// MARK: - LLM Provider Protocol

protocol LLMProvider: Identifiable {
    var info: ProviderInfo { get }
    var isInstalled: Bool { get }
    func fetchUsage() -> ProviderUsage?
}

extension LLMProvider {
    var id: String { info.id }
}
