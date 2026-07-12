import Foundation

/// A brightness adjustment for a specific display, triggered by a global hotkey.
/// The change is a single SIGNED step — positive brightens, negative dims — so
/// direction and amount are one value.
struct Macro: Identifiable, Codable, Equatable {
    /// A global keyboard shortcut, stored as Carbon key code + modifier mask.
    struct Shortcut: Codable, Equatable {
        var keyCode: UInt32
        var modifiers: UInt32  // Carbon mask (cmdKey / optionKey / controlKey / shiftKey)
        var label: String  // display label for the key, e.g. "↑", "B", "F13"
    }

    var id = UUID()
    /// Stable target display (vendor-model-serial); survives reconnects.
    var displayKey: String
    /// Human-readable target name, shown when the display is currently absent.
    var displayName: String
    /// Signed brightness change in -1...1, e.g. +0.10 brightens 10%, -0.10 dims 10%.
    var step: Double
    var shortcut: Shortcut? = nil

    /// Signed change applied to the target's brightness.
    var delta: Double { step }

    /// Signed percentage label, e.g. "+10%" or "−10%".
    var signedPercent: String {
        let pct = Int((abs(step) * 100).rounded())
        return "\(step < 0 ? "−" : "+")\(pct)%"
    }
}
