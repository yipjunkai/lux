import AppKit
import Carbon
import Foundation

// Program entry runs on the main thread, so we adopt the main actor explicitly.
// This keeps the AppKit/SwiftUI objects (all main-actor isolated) happy without
// fighting the concurrency checker at startup.
MainActor.assumeIsolated {
    let args = CommandLine.arguments

    // Diagnostic / scripting hooks. Handy during development and for power users.
    if args.contains("--list-displays") {
        DisplayManager.printDisplaysToConsole()
        exit(0)
    }
    if args.contains("--get-brightness") {
        let displays = DisplayManager.activeDisplays()
        DDCManager.shared.refresh(displays: displays)
        for d in displays {
            let pct = Int((BrightnessController.currentBrightness(for: d) * 100).rounded())
            print("  • \(d.name): \(pct)%  via \(BrightnessController.backend(for: d).label)")
        }
        exit(0)
    }
    if let i = args.firstIndex(of: "--set-brightness"), i + 1 < args.count, let v = Double(args[i + 1]) {
        let displays = DisplayManager.activeDisplays()
        DDCManager.shared.refresh(displays: displays)
        for d in displays {
            let ok = BrightnessController.setBrightness(v, for: d)
            let backend = BrightnessController.backend(for: d)
            print("  • \(d.name): → \(Int((v * 100).rounded()))%  \(ok ? "ok" : "failed")  (\(backend.label))")
        }
        // DDC writes are coalesced on a background queue — give them a beat to flush.
        usleep(200_000)
        print("Note: software-dimmed displays stay dimmed until you run:  Lux --restore")
        exit(0)
    }
    if args.contains("--restore") {
        BrightnessController.restoreAll()
        print("Restored gamma for all displays.")
        exit(0)
    }
    if args.contains("--selftest-set") {
        // Set each display to its OWN current value: verifies the write path with
        // zero visible change.
        let displays = DisplayManager.activeDisplays()
        DDCManager.shared.refresh(displays: displays)
        for d in displays {
            let cur = BrightnessController.currentBrightness(for: d)
            let ok = BrightnessController.setBrightness(cur, for: d)
            print("  • \(d.name): write→\(Int((cur * 100).rounded()))% returned \(ok ? "ok ✅" : "failed ❌")  (\(BrightnessController.backend(for: d).label))")
        }
        usleep(250_000) // let coalesced DDC writes flush
        exit(0)
    }
    if args.contains("--probe-ddc") {
        print("DDC private API resolved: \(DDC.isSupported)")
        let services = DDC.discoverServices()
        print("Found \(services.count) AV service(s):")
        for (i, s) in services.enumerated() {
            print("  [\(i)] location=\(s.location) vendor=\(s.vendorID.map(String.init) ?? "?") product=\(s.productID.map(String.init) ?? "?") serial=\(s.serial.map(String.init) ?? "?")")
        }
        for d in DisplayManager.activeDisplays() where !d.isBuiltin {
            print("\nDisplay \"\(d.name)\" (vendor=\(d.vendor) model=\(d.model)):")
            guard let svc = DDC.service(for: d, in: services) else {
                print("  → no matching AV service found")
                continue
            }
            if let (cur, maxV) = DDC.readVCP(svc, code: 0x10) {
                let pct = maxV > 0 ? Int((Double(cur) / Double(maxV) * 100).rounded()) : 0
                print("  → DDC OK ✅  brightness \(cur)/\(maxV)  (\(pct)%)")
            } else {
                print("  → matched a service, but VCP 0x10 read failed (panel may not support DDC)")
            }
        }
        exit(0)
    }

    if args.contains("--test-observer") {
        // Verify the DisplayServices change-notification path: register, nudge the
        // built-in brightness to trigger the callback, then restore. Pumps the run
        // loop so the notification can be delivered.
        let registered = BuiltInBrightness.registerForChangeNotifications()
        print("registered: \(registered)")
        if let builtin = DisplayManager.activeDisplays().first(where: { $0.isBuiltin }),
           let cur = BuiltInBrightness.get(builtin.id) {
            let nudge: Float = cur >= 0.5 ? cur - 0.05 : cur + 0.05
            print("nudging built-in \(Int(cur * 100))% → \(Int(nudge * 100))% to trigger the callback…")
            BuiltInBrightness.set(builtin.id, nudge)
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            BuiltInBrightness.set(builtin.id, cur)
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            print("restored to \(Int(cur * 100))%")
        }
        exit(0)
    }

    if args.contains("--dump-macros") {
        for m in MacroStore.shared.macros {
            print("  • \(m.signedPercent) → \(m.displayName)  [shortcut: \(m.shortcut?.displayString ?? "none")]")
        }
        print("(\(MacroStore.shared.macros.count) macro(s))")
        exit(0)
    }
    if args.contains("--add-sample-macro") {
        let displays = DisplayManager.activeDisplays()
        if let d = displays.first(where: { !$0.isBuiltin }) ?? displays.first {
            let mods = UInt32(controlKey | optionKey) // ⌃⌥
            MacroStore.shared.add(Macro(displayKey: d.stableKey, displayName: d.name, step: 0.10,
                                        shortcut: Macro.Shortcut(keyCode: 126, modifiers: mods, label: "↑")))
            MacroStore.shared.add(Macro(displayKey: d.stableKey, displayName: d.name, step: -0.10,
                                        shortcut: Macro.Shortcut(keyCode: 125, modifiers: mods, label: "↓")))
            print("added ⌃⌥↑ / ⌃⌥↓ macros for \(d.name)")
        }
        exit(0)
    }
    if args.contains("--clear-macros") {
        for m in MacroStore.shared.macros { MacroStore.shared.remove(m) }
        print("cleared macros")
        exit(0)
    }

    if args.contains("--login-status") {
        print("login item: \(LoginItem.statusDescription)")
        exit(0)
    }
    if args.contains("--enable-login") {
        let ok = LoginItem.setEnabled(true)
        print("register \(ok ? "ok" : "failed") — status: \(LoginItem.statusDescription)")
        exit(0)
    }
    if args.contains("--disable-login") {
        let ok = LoginItem.setEnabled(false)
        print("unregister \(ok ? "ok" : "failed") — status: \(LoginItem.statusDescription)")
        exit(0)
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory) // menu bar only, no Dock icon
    app.run()
}
