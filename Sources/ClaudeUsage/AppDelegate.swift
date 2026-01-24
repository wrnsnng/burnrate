import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel = UsageViewModel()
    private var eventMonitor: Any?
    private var analyticsWindow: NSWindow?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[DEBUG] applicationDidFinishLaunching started")

        // Request notification permissions
        viewModel.notificationService.requestPermissions()

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
            rootView: ContentView(
                viewModel: viewModel,
                onQuit: { [weak self] in
                    self?.quit()
                },
                onShowAnalytics: { [weak self] in
                    self?.showAnalyticsWindow()
                },
                onShowSettings: { [weak self] in
                    self?.showSettingsWindow()
                }
            )
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

    private func showAnalyticsWindow() {
        // Close popover first
        closePopover()

        // If window already exists, just bring it to front
        if let window = analyticsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create analytics window
        let analyticsView = AnalyticsView(
            snapshots: viewModel.snapshots,
            todayStats: viewModel.todayStats,
            weekStats: viewModel.weekStats
        )

        let hostingController = NSHostingController(rootView: analyticsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Claude Usage Analytics"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 400, height: 550))
        window.center()
        window.isReleasedWhenClosed = false

        // Clean up reference when window closes
        window.delegate = self

        analyticsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showSettingsWindow() {
        // Close popover first
        closePopover()

        // If window already exists, just bring it to front
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create settings window
        let settingsView = SettingsView(
            settingsService: viewModel.settingsService,
            notificationService: viewModel.notificationService
        )

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 350, height: 280))
        window.center()
        window.isReleasedWhenClosed = false

        // Clean up reference when window closes
        window.delegate = self

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window == analyticsWindow {
            analyticsWindow = nil
        } else if window == settingsWindow {
            settingsWindow = nil
        }
    }
}
