import ServiceManagement

/// Launch-at-login via `SMAppService` (macOS 13+). The system remembers the
/// setting itself, so there's nothing for us to persist — we just read and flip
/// the registration status of our own app bundle.
///
/// Caveats: this only works when running the real `Lux.app` bundle (not
/// `swift run`), and for a stable login item the app should live in /Applications
/// (a path under build/ works for testing but breaks if the build is cleaned).
enum LoginItem {

    static var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval: return true
        default: return false
        }
    }

    /// True when macOS has the item registered but is waiting for the user to
    /// approve it in System Settings › General › Login Items.
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled: return "enabled"
        case .notRegistered: return "not registered"
        case .requiresApproval: return "requires approval"
        case .notFound: return "not found"
        @unknown default: return "unknown"
        }
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            print("[Lux] launch-at-login \(enabled ? "register" : "unregister") failed: \(error)")
            return false
        }
    }

    static func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
