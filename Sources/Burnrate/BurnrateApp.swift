import AppKit
import SwiftUI

@main
struct BurnrateApp {
    static func main() {
        NSLog("[DEBUG] main() starting")
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        NSLog("[DEBUG] Starting run loop")
        app.run()
    }
}
