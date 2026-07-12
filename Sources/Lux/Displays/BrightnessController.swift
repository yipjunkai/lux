import CoreGraphics

/// Which mechanism is controlling a given display's brightness.
enum BrightnessBackend {
    case backlight  // built-in / Apple displays via DisplayServices — real backlight
    case ddc  // external via DDC/CI — real backlight
    case software  // gamma dimming — works anywhere, darkens the image

    var label: String {
        switch self {
        case .backlight: return "hardware backlight"
        case .ddc: return "DDC/CI backlight"
        case .software: return "software dimming"
        }
    }
}

/// The single entry point the UI and automation use. Routes each display to the
/// right backend and presents one uniform 0...1 brightness model.
struct BrightnessController {

    /// Decide how to control a display: built-in → DisplayServices, external with
    /// working DDC → DDC, otherwise software (gamma) dimming as the fallback.
    static func backend(for display: DisplayInfo) -> BrightnessBackend {
        if display.isBuiltin && BuiltInBrightness.isAvailable {
            return .backlight
        }
        if DDCManager.shared.controls(display.id) {
            return .ddc
        }
        return .software
    }

    /// Current brightness in 0...1.
    static func currentBrightness(for display: DisplayInfo) -> Double {
        switch backend(for: display) {
        case .backlight:
            return Double(BuiltInBrightness.get(display.id) ?? 1.0)
        case .ddc:
            return DDCManager.shared.brightness(display.id) ?? 1.0
        case .software:
            return GammaDimmer.level(for: display.id)
        }
    }

    /// Set brightness in 0...1. Returns true on success.
    @discardableResult
    static func setBrightness(_ value: Double, for display: DisplayInfo) -> Bool {
        let v = max(0, min(1, value))
        switch backend(for: display) {
        case .backlight:
            return BuiltInBrightness.set(display.id, Float(v))
        case .ddc:
            return DDCManager.shared.setBrightness(v, for: display.id)
        case .software:
            return GammaDimmer.set(v, for: display.id)
        }
    }

    /// Undo any software dimming — called on quit so we never leave a display dim.
    static func restoreAll() {
        GammaDimmer.restoreAll()
    }
}
