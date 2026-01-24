import Foundation

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

    init() {
        let saved = UserDefaults.standard.string(forKey: "menubarDisplay") ?? MenubarDisplay.sevenDay.rawValue
        self.menubarDisplay = MenubarDisplay(rawValue: saved) ?? .sevenDay
    }
}
