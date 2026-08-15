import Foundation
import ServiceManagement

enum MenubarDisplay: String, CaseIterable, Identifiable {
    case sevenDay = "7-day usage"
    case fiveHour = "5-hour usage"
    case both = "Both (5h|7d)"
    case iconOnly = "Icon only"
    case chart = "Chart"

    var id: String { rawValue }
}

enum MenubarColorScheme: String, CaseIterable, Identifiable {
    case dynamic = "Dynamic"
    case distinct = "Distinct"
    case monochrome = "Monochrome"

    var id: String { rawValue }
}

enum MenubarSource: String, CaseIterable, Identifiable {
    case claude = "Claude"
    case codex = "Codex"
    case kimi = "Kimi K2.5"
    case gemini = "Gemini"

    var id: String { rawValue }
}

@Observable
final class SettingsService {
    var menubarDisplay: MenubarDisplay {
        didSet {
            UserDefaults.standard.set(menubarDisplay.rawValue, forKey: "menubarDisplay")
        }
    }

    var menubarColorScheme: MenubarColorScheme {
        didSet {
            UserDefaults.standard.set(menubarColorScheme.rawValue, forKey: "menubarColorScheme")
        }
    }

    var menubarSource: MenubarSource {
        didSet {
            UserDefaults.standard.set(menubarSource.rawValue, forKey: "menubarSource")
        }
    }

    var supabaseSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(supabaseSyncEnabled, forKey: "supabaseSyncEnabled")
        }
    }

    /// Persistent user ID for Supabase row ownership. Auto-generated on first access.
    var supabaseUserId: String {
        didSet {
            UserDefaults.standard.set(supabaseUserId, forKey: "supabaseUserId")
            NSUbiquitousKeyValueStore.default.set(supabaseUserId, forKey: "supabaseUserId")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    var launchAtStartup: Bool {
        get {
            guard Bundle.main.bundleIdentifier != nil else { return false }
            return SMAppService.mainApp.status == .enabled
        }
        set {
            guard Bundle.main.bundleIdentifier != nil else {
                NSLog("[Settings] Launch at login requires running as bundled .app")
                return
            }
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("[Settings] Failed to update launch at startup: \(error)")
            }
        }
    }

    var canUseLaunchAtLogin: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    init() {
        let savedDisplay = UserDefaults.standard.string(forKey: "menubarDisplay") ?? MenubarDisplay.sevenDay.rawValue
        self.menubarDisplay = MenubarDisplay(rawValue: savedDisplay) ?? .sevenDay

        let savedColorScheme = UserDefaults.standard.string(forKey: "menubarColorScheme") ?? MenubarColorScheme.dynamic.rawValue
        self.menubarColorScheme = MenubarColorScheme(rawValue: savedColorScheme) ?? .dynamic

        let savedSource = UserDefaults.standard.string(forKey: "menubarSource") ?? MenubarSource.claude.rawValue
        self.menubarSource = MenubarSource(rawValue: savedSource) ?? .claude

        self.supabaseSyncEnabled = UserDefaults.standard.bool(forKey: "supabaseSyncEnabled")

        // Load user ID: prefer iCloud (for cross-device sync), fallback to local, or generate new
        if let icloudId = NSUbiquitousKeyValueStore.default.string(forKey: "supabaseUserId"), !icloudId.isEmpty {
            self.supabaseUserId = icloudId
            UserDefaults.standard.set(icloudId, forKey: "supabaseUserId")
        } else if let localId = UserDefaults.standard.string(forKey: "supabaseUserId"), !localId.isEmpty {
            self.supabaseUserId = localId
            NSUbiquitousKeyValueStore.default.set(localId, forKey: "supabaseUserId")
            NSUbiquitousKeyValueStore.default.synchronize()
        } else {
            let newId = UUID().uuidString
            self.supabaseUserId = newId
            UserDefaults.standard.set(newId, forKey: "supabaseUserId")
            NSUbiquitousKeyValueStore.default.set(newId, forKey: "supabaseUserId")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
}
