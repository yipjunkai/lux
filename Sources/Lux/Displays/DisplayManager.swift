import AppKit
import CoreGraphics

/// A connected display and the facts we need to identify and control it.
struct DisplayInfo: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let isBuiltin: Bool
    let vendor: UInt32
    let model: UInt32
    let serial: UInt32
    let width: Int
    let height: Int

    /// Stable identifier that survives reboots / reconnects (unlike `id`, which
    /// macOS can reassign). Used to bind macros to a specific physical display.
    var stableKey: String { "\(vendor)-\(model)-\(serial)" }
}

/// Enumerates the displays currently attached to the system.
///
/// This is the foundation everything else builds on: each control mechanism
/// (DisplayServices for built-in, DDC/CI for external, gamma fallback) keys off
/// the `CGDirectDisplayID` we surface here.
enum DisplayManager {

    static func activeDisplays() -> [DisplayInfo] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
            return []
        }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else {
            return []
        }

        // Map display IDs to NSScreen so we can read human-friendly names.
        var screensByID: [CGDirectDisplayID: NSScreen] = [:]
        for screen in NSScreen.screens {
            if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                as? NSNumber
            {
                screensByID[CGDirectDisplayID(number.uint32Value)] = screen
            }
        }

        return ids.prefix(Int(count)).map { id in
            let mode = CGDisplayCopyDisplayMode(id)
            let name = screensByID[id]?.localizedName ?? "Display \(id)"
            return DisplayInfo(
                id: id,
                name: name,
                isBuiltin: CGDisplayIsBuiltin(id) != 0,
                vendor: CGDisplayVendorNumber(id),
                model: CGDisplayModelNumber(id),
                serial: CGDisplaySerialNumber(id),
                width: mode?.pixelWidth ?? Int(CGDisplayPixelsWide(id)),
                height: mode?.pixelHeight ?? Int(CGDisplayPixelsHigh(id))
            )
        }
    }

    /// Diagnostic dump used by `Lux --list-displays`.
    static func printDisplaysToConsole() {
        let displays = activeDisplays()
        guard !displays.isEmpty else {
            print("No active displays detected.")
            return
        }
        print("Detected \(displays.count) display(s):")
        for d in displays {
            let kind = d.isBuiltin ? "built-in" : "external"
            print(
                "  • \(d.name)  [\(kind)]  id=\(d.id)  \(d.width)×\(d.height)  vendor=\(d.vendor) model=\(d.model)"
            )
        }
    }
}
