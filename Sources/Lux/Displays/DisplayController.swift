import AppKit
import Combine
import CoreGraphics

/// The observable source of truth for the UI. Holds one item per display and
/// keeps its brightness in sync with the real hardware:
///
/// - **Built-in:** event-driven. `BuiltInBrightness` registers a DisplayServices
///   callback that fires on any brightness change (keys, Control Center, us), and
///   we re-read in `builtInBrightnessChanged()`.
/// - **External (DDC):** read on `reload()` — i.e. whenever the popover opens —
///   because DDC has no change events.
@MainActor
final class DisplayController: ObservableObject {
    static let shared = DisplayController()

    struct Item: Identifiable {
        let info: DisplayInfo
        var brightness: Double
        let backend: BrightnessBackend
        var id: CGDirectDisplayID { info.id }
    }

    @Published private(set) var items: [Item] = []

    private var dragging: Set<CGDirectDisplayID> = []
    private var observerRegistered = false
    private var screenObserver: NSObjectProtocol?
    private var pendingReload: DispatchWorkItem?

    /// How long to wait after the last display-configuration notification before
    /// re-scanning, so a dock/undock's burst of events collapses into one reload
    /// and freshly-attached panels get a beat to come up before we read them.
    private static let reloadDebounce: TimeInterval = 0.5

    /// Re-read every display. Called at launch and each time the popover opens —
    /// this is how external (DDC) displays catch up to outside changes.
    func reload() {
        let displays = DisplayManager.activeDisplays()
        DDCManager.shared.refresh(displays: displays)
        items = displays.map {
            Item(
                info: $0,
                brightness: BrightnessController.currentBrightness(for: $0),
                backend: BrightnessController.backend(for: $0)
            )
        }
        if !observerRegistered {
            observerRegistered = BuiltInBrightness.registerForChangeNotifications()
        }
        registerForDisplayChanges()
    }

    /// Re-scan automatically when the display layout changes. On reconnect macOS
    /// reassigns `CGDirectDisplayID`s and our cached DDC service handles go stale,
    /// so a slider still bound to the old id silently drives nothing until the
    /// next `reload()`. Observing `didChangeScreenParametersNotification` (connect,
    /// disconnect, rearrange, resolution) lets Lux self-heal without the user
    /// opening the popover or pressing Refresh.
    private func registerForDisplayChanges() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Delivered on `.main` (OperationQueue.main), so we're on the main actor.
            MainActor.assumeIsolated { self?.scheduleReloadAfterDisplayChange() }
        }
    }

    /// Debounce the storm of notifications macOS emits during a single dock/undock
    /// into one trailing `reload()`.
    private func scheduleReloadAfterDisplayChange() {
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in
            print("[Lux] display configuration changed — re-scanning displays")
            self?.reload()
        }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.reloadDebounce, execute: work)
    }

    func brightness(for id: CGDirectDisplayID) -> Double {
        items.first(where: { $0.id == id })?.brightness ?? 1.0
    }

    /// Apply a user-driven change (from a slider).
    func set(_ value: Double, for id: CGDirectDisplayID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let clamped = max(0, min(1, value))
        items[idx].brightness = clamped
        BrightnessController.setBrightness(clamped, for: items[idx].info)
    }

    func beginDragging(_ id: CGDirectDisplayID) { dragging.insert(id) }
    func endDragging(_ id: CGDirectDisplayID) { dragging.remove(id) }

    /// Find the current item for a macro's stable display key (nil if unplugged).
    func item(forKey key: String) -> Item? {
        items.first { $0.info.stableKey == key }
    }

    /// Run a macro: nudge its target display by the macro's signed delta.
    @discardableResult
    func runMacro(_ macro: Macro) -> Bool {
        guard let target = item(forKey: macro.displayKey) else { return false }
        set(brightness(for: target.id) + macro.delta, for: target.id)
        return true
    }

    /// Invoked on the main thread from the DisplayServices brightness callback.
    /// We re-read the built-ins; displays the user is actively dragging are left
    /// alone so we don't fight them.
    func builtInBrightnessChanged() {
        for idx in items.indices where items[idx].info.isBuiltin {
            if dragging.contains(items[idx].id) { continue }
            let fresh = BrightnessController.currentBrightness(for: items[idx].info)
            if abs(fresh - items[idx].brightness) > 0.0005 {
                items[idx].brightness = fresh
            }
        }
    }
}
