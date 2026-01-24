import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel = UsageViewModel()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[DEBUG] applicationDidFinishLaunching started")

        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        NSLog("[DEBUG] statusItem created")

        if let button = statusItem.button {
            updateMenubarTitle()
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 650)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: ContentView(viewModel: viewModel, onQuit: { [weak self] in
                self?.quit()
            })
        )

        // Start auto-refresh
        NSLog("[DEBUG] Starting auto-refresh...")
        viewModel.startAutoRefresh()
        NSLog("[DEBUG] Auto-refresh started")

        // Observe viewModel changes to update menubar title
        startObservingViewModel()

        // Monitor for clicks outside popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stopAutoRefresh()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func startObservingViewModel() {
        // Poll for changes (simpler than Combine for this use case)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenubarTitle()
        }
    }

    private func updateMenubarTitle() {
        guard let button = statusItem.button else { return }

        let title = viewModel.menubarTitle
        button.title = "⚡ \(title)"
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
