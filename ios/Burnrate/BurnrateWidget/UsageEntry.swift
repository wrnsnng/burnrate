import WidgetKit
import Foundation

// MARK: - Timeline Entry

struct UsageEntry: TimelineEntry {
    let date: Date
    let providers: [ProviderData]
    let lastUpdated: Date?
    let isPlaceholder: Bool

    static let placeholder = UsageEntry(
        date: .now,
        providers: [
            ProviderData(
                id: "claude",
                name: "Claude",
                primaryUtilization: 42,
                primaryLabel: "5-hour",
                primaryResetsAt: Date().addingTimeInterval(3600),
                secondaryUtilization: 28,
                secondaryLabel: "7-day",
                secondaryResetsAt: Date().addingTimeInterval(86400)
            ),
            ProviderData(
                id: "codex",
                name: "Codex",
                primaryUtilization: 65,
                primaryLabel: "Daily",
                primaryResetsAt: Date().addingTimeInterval(7200),
                secondaryUtilization: nil,
                secondaryLabel: nil,
                secondaryResetsAt: nil
            ),
        ],
        lastUpdated: .now,
        isPlaceholder: true
    )

    static let empty = UsageEntry(
        date: .now,
        providers: [],
        lastUpdated: nil,
        isPlaceholder: false
    )
}

// MARK: - Provider Data

struct ProviderData: Identifiable, Codable {
    let id: String
    let name: String
    let primaryUtilization: Double
    let primaryLabel: String
    let primaryResetsAt: Date?
    let secondaryUtilization: Double?
    let secondaryLabel: String?
    let secondaryResetsAt: Date?

    /// Map raw provider id from Supabase to a display name.
    static func displayName(for providerId: String) -> String {
        switch providerId.lowercased() {
        case "claude": return "Claude"
        case "codex": return "Codex"
        case "kimi": return "Kimi K2.5"
        case "gemini": return "Gemini"
        default: return providerId.capitalized
        }
    }
}
