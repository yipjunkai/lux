import AppKit
import Carbon
import SwiftUI

extension Macro.Shortcut {
    /// Human-readable form like "⌃⌥↑" or "F13".
    var displayString: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        return s + label
    }
}

enum KeyTranslator {
    static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.option) { m |= UInt32(optionKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        if flags.contains(.shift) { m |= UInt32(shiftKey) }
        return m
    }

    static func label(keyCode: UInt32, characters: String?) -> String {
        if let special = specialKeys[keyCode] { return special }
        if let ch = characters, !ch.isEmpty, ch != " " { return ch.uppercased() }
        return "key\(keyCode)"
    }

    /// Function-key virtual key codes (F1–F20). These make good macro keys and
    /// are allowed as bare shortcuts (no modifier needed).
    static let functionKeyCodes: Set<UInt32> = [
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, // F1–F12
        105, 107, 113, 106, 64, 79, 80, 90,                     // F13–F20
    ]

    private static let specialKeys: [UInt32: String] = [
        126: "↑", 125: "↓", 123: "←", 124: "→",
        49: "Space", 36: "↩", 48: "⇥", 51: "⌫", 117: "⌦",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16",
        64: "F17", 79: "F18", 80: "F19", 90: "F20",
        115: "Home", 119: "End", 116: "PgUp", 121: "PgDn",
    ]
}

/// A click-to-record control that captures a key combo for a macro. Accepts any
/// key with ⌘/⌥/⌃, plus bare function keys (F1–F20) for macro-key setups.
struct ShortcutRecorder: View {
    let shortcut: Macro.Shortcut?
    let onChange: (Macro.Shortcut?) -> Void

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button {
                recording ? stop() : start()
            } label: {
                Text(labelText)
                    .frame(minWidth: 104)
            }

            if shortcut != nil && !recording {
                Button { onChange(nil) } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Clear shortcut")
            }
        }
        .onDisappear(perform: stop)
    }

    private var labelText: String {
        if recording { return "Press keys…" }
        return shortcut?.displayString ?? "Record shortcut"
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == 53 { stop(); return nil } // Esc cancels
            let keyCode = UInt32(event.keyCode)
            let modifiers = KeyTranslator.carbonModifiers(event.modifierFlags)
            // Accept anything with ⌘/⌥/⌃, or a bare function key.
            let modifierMask = UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey)
            let hasModifier = modifiers & modifierMask != 0
            guard hasModifier || KeyTranslator.functionKeyCodes.contains(keyCode) else { return nil }
            let label = KeyTranslator.label(keyCode: keyCode, characters: event.charactersIgnoringModifiers)
            onChange(Macro.Shortcut(keyCode: keyCode, modifiers: modifiers, label: label))
            stop()
            return nil
        }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
