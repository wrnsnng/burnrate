import Foundation
import ServiceManagement

enum PreferredTerminal: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm2 = "iTerm2"
    case warp = "Warp"
    case ghostty = "Ghostty"

    var id: String { rawValue }

    var bundlePath: String {
        switch self {
        case .terminal: return "/System/Applications/Utilities/Terminal.app"
        case .iterm2: return "/Applications/iTerm.app"
        case .warp: return "/Applications/Warp.app"
        case .ghostty: return "/Applications/Ghostty.app"
        }
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: bundlePath)
    }

    static func autoDetect() -> PreferredTerminal {
        let preferred: [PreferredTerminal] = [.ghostty, .warp, .iterm2]
        return preferred.first { $0.isInstalled } ?? .terminal
    }
}

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

@Observable
final class SettingsService {
    var preferredTerminal: PreferredTerminal {
        didSet {
            UserDefaults.standard.set(preferredTerminal.rawValue, forKey: "preferredTerminal")
        }
    }

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
        let savedTerminal = UserDefaults.standard.string(forKey: "preferredTerminal")
        if let saved = savedTerminal, let terminal = PreferredTerminal(rawValue: saved) {
            self.preferredTerminal = terminal
        } else {
            self.preferredTerminal = PreferredTerminal.autoDetect()
        }

        let savedDisplay = UserDefaults.standard.string(forKey: "menubarDisplay") ?? MenubarDisplay.sevenDay.rawValue
        self.menubarDisplay = MenubarDisplay(rawValue: savedDisplay) ?? .sevenDay

        let savedColorScheme = UserDefaults.standard.string(forKey: "menubarColorScheme") ?? MenubarColorScheme.dynamic.rawValue
        self.menubarColorScheme = MenubarColorScheme(rawValue: savedColorScheme) ?? .dynamic
    }
}
