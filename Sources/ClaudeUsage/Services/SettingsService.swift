import Foundation

enum MenubarDisplay: String, CaseIterable, Identifiable {
    case sevenDay = "7-Day Usage"
    case fiveHour = "5-Hour Usage"
    case both = "Both (5h|7d)"
    case iconOnly = "Icon Only"

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
