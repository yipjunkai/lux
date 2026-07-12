import CoreGraphics
import Foundation

/// Real hardware-backlight control for the built-in display (and Apple external
/// displays) via the private `DisplayServices` framework, plus registration for
/// system brightness-change notifications so the UI stays in sync when brightness
/// changes from outside Lux (the F1/F2 keys, Control Center, etc.).
///
/// Symbols are resolved at runtime with `dlopen`/`dlsym` rather than linked, so
/// the build stays clean and everything degrades gracefully if a symbol is gone.
enum BuiltInBrightness {

    private typealias GetFn =
        @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias RegisterFn = @convention(c) (UInt32, UInt64, DSBrightnessCallback) -> Int32

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_NOW
    )

    private static let getFn: GetFn? =
        handle
        .flatMap { dlsym($0, "DisplayServicesGetBrightness") }
        .map { unsafeBitCast($0, to: GetFn.self) }

    private static let setFn: SetFn? =
        handle
        .flatMap { dlsym($0, "DisplayServicesSetBrightness") }
        .map { unsafeBitCast($0, to: SetFn.self) }

    private static let registerFn: RegisterFn? =
        handle
        .flatMap { dlsym($0, "DisplayServicesRegisterForBrightnessChangeNotifications") }
        .map { unsafeBitCast($0, to: RegisterFn.self) }

    static var isAvailable: Bool { getFn != nil && setFn != nil }

    static func get(_ display: CGDirectDisplayID) -> Float? {
        guard let getFn else { return nil }
        var value: Float = 0
        return getFn(display, &value) == 0 ? value : nil
    }

    @discardableResult
    static func set(_ display: CGDirectDisplayID, _ value: Float) -> Bool {
        guard let setFn else { return false }
        let clamped = max(0, min(1, value))
        return setFn(display, clamped) == 0
    }

    /// Register for system brightness-change notifications on the built-in
    /// display(s). The callback fires whenever brightness changes from any source.
    @discardableResult
    static func registerForChangeNotifications() -> Bool {
        guard let registerFn else {
            print("[Lux] DisplayServices change notifications unavailable")
            return false
        }
        var ok = false
        for display in DisplayManager.activeDisplays() where display.isBuiltin {
            if registerFn(display.id, 0, luxBrightnessChangeCallback) == 0 { ok = true }
        }
        print("[Lux] brightness observer registered: \(ok)")
        return ok
    }
}

/// C callback type for DisplayServices brightness notifications. The private
/// API's exact argument layout is ambiguous across macOS versions, so we ignore
/// the arguments entirely — any invocation simply means "re-read the built-ins".
typealias DSBrightnessCallback =
    @convention(c) (UnsafeRawPointer?, UInt32, UInt32, UnsafeRawPointer?) -> Void

private func luxBrightnessChangeCallback(
    _ refcon: UnsafeRawPointer?,
    _ service: UInt32,
    _ messageType: UInt32,
    _ messageArgument: UnsafeRawPointer?
) {
    DispatchQueue.main.async {
        DisplayController.shared.builtInBrightnessChanged()
    }
}
