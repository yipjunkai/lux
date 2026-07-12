import AppKit
import SwiftUI

/// Owns the menu bar item and the popover that hosts the SwiftUI UI.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Read displays, probe DDC, and register the brightness-change observer
        // before building the UI so initial slider values are correct.
        DisplayController.shared.reload()
        HotkeyManager.shared.reload(MacroStore.shared.macros)
        DisplayManager.printDisplaysToConsole()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Lux")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.behavior = .transient
        // Let the popover hug the SwiftUI content's natural size — a fixed
        // contentSize taller than the content makes SwiftUI center it, leaving
        // a gap at the top.
        let hosting = NSHostingController(rootView: RootView())
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
    }

    /// Undo any software (gamma) dimming on quit so we never leave a display dim.
    func applicationWillTerminate(_ notification: Notification) {
        BrightnessController.restoreAll()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
