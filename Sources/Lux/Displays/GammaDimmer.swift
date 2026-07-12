import CoreGraphics

/// Software dimming via the display's gamma table. The universal fallback: works
/// on *any* display, including external panels that don't support DDC. It darkens
/// the image rather than the backlight, and can dim below a panel's hardware
/// minimum.
///
/// The gamma API has no getter, so we track the level we last applied. Note that
/// gamma changes are system state that persists after our process exits — call
/// `restoreAll()` on quit (we do) so we never leave a display stuck dim.
enum GammaDimmer {

    private static var levels: [CGDirectDisplayID: Double] = [:]

    static func level(for display: CGDirectDisplayID) -> Double {
        levels[display] ?? 1.0
    }

    /// Apply a brightness scale in 0...1 by capping the top of the color ramp.
    @discardableResult
    static func set(_ value: Double, for display: CGDirectDisplayID) -> Bool {
        let v = CGGammaValue(max(0.0, min(1.0, value)))
        let err = CGSetDisplayTransferByFormula(
            display,
            0, v, 1,   // red:   min, max, gamma
            0, v, 1,   // green: min, max, gamma
            0, v, 1    // blue:  min, max, gamma
        )
        guard err == .success else { return false }
        levels[display] = Double(v)
        return true
    }

    /// Reset one display back to full (identity ramp).
    static func restore(_ display: CGDirectDisplayID) {
        _ = set(1.0, for: display)
        levels[display] = nil
    }

    /// Reset every display's gamma to the system default.
    static func restoreAll() {
        CGDisplayRestoreColorSyncSettings()
        levels.removeAll()
    }
}
