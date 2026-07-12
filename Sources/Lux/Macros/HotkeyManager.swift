import AppKit
import Carbon

/// Registers each macro's global hotkey via Carbon `RegisterEventHotKey`. These
/// fire system-wide (regardless of the frontmost app) and need no special
/// permissions. On a keypress we look up the macro by id and run it.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var refs: [EventHotKeyRef] = []
    private var macrosByID: [UInt32: Macro] = [:]
    private var nextID: UInt32 = 1
    private var handlerInstalled = false
    private let signature: OSType = 0x4C555858 // 'LUXX'

    /// Re-register hotkeys for the given macros. Call whenever macros change.
    func reload(_ macros: [Macro]) {
        installHandlerIfNeeded()

        for ref in refs { UnregisterEventHotKey(ref) }
        refs.removeAll()
        macrosByID.removeAll()

        for macro in macros {
            guard let shortcut = macro.shortcut else { continue }
            let id = nextID
            nextID &+= 1
            let hotKeyID = EventHotKeyID(signature: signature, id: id)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                refs.append(ref)
                macrosByID[id] = macro
            }
        }
    }

    /// Called (on the main thread) from the Carbon event handler.
    func trigger(id: UInt32) {
        guard let macro = macrosByID[id] else { return }
        // Invoked on the main thread via the handler's main-queue dispatch.
        _ = MainActor.assumeIsolated {
            DisplayController.shared.runMacro(macro)
        }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetEventDispatcherTarget(), luxHotkeyHandler, 1, &spec, nil, nil)
        handlerInstalled = true
    }
}

/// Carbon C callback — extracts the hot key id and dispatches to the manager.
private func luxHotkeyHandler(_ call: EventHandlerCallRef?,
                              _ event: EventRef?,
                              _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let err = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    if err == noErr {
        let id = hotKeyID.id
        DispatchQueue.main.async { HotkeyManager.shared.trigger(id: id) }
    }
    return noErr
}
