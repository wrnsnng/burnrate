import Foundation
import ServiceManagement

enum MenubarDisplay: String, CaseIterable, Identifiable {
    case sevenDay = "7-day usage"
    case fiveHour = "5-hour usage"
    case both = "Both (5h|7d)"
    case iconOnly = "Icon only"

    var id: String { rawValue }
}

@Observable
final class SettingsService {
    var menubarDisplay: MenubarDisplay {
        didSet {
            UserDefaults.standard.set(menubarDisplay.rawValue, forKey: "menubarDisplay")
        }
    }

    var launchAtStartup: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
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

    init() {
        let saved = UserDefaults.standard.string(forKey: "menubarDisplay") ?? MenubarDisplay.sevenDay.rawValue
        self.menubarDisplay = MenubarDisplay(rawValue: saved) ?? .sevenDay
    }
}
