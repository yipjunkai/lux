# Lux

A native macOS menu bar app for controlling the brightness of **all your displays** —
built-in and external — with time-based automation and custom macro buttons.

> **Status:** 🟢 Phase 1 complete (real backlight control on every display, live
> sync with the brightness keys, launch-at-login) and **Phase 3 macros v1** working
> (per-display ±N% buttons, configured in a Settings window and saved to disk).
> Macros are triggered by **global hotkeys**. Next: automation (Phase 2).
>
> **Locked:** native **Swift** (SwiftUI + AppKit), **Swift Package Manager**, targeting
> Apple Silicon / macOS 14+. Open-source (MIT proposed), distributed as a
> Developer-ID-signed **Homebrew Cask**.

---

## The pitch

macOS gives you a brightness key for the built-in display and… basically nothing for
external monitors. Lux lives in your menu bar and gives every connected display a real
brightness slider, then layers automation on top:

- 🖥️ **Multi-monitor control** — one slider per display, built-in + external.
- ⏰ **Time-based automation** — displays dim and brighten on a schedule / with the sun.
- 🎛️ **Macros** — custom one-tap buttons ("Movie", "Focus", "Bright") and optional hotkeys.
- 🍫 **Menu bar native** — lightweight, no Dock icon, launches at login.

---

## How brightness control actually works

There is no single API. Lux uses the right mechanism per display, with a fallback:

| Display | Mechanism | Notes |
|---|---|---|
| **Built-in** (MacBook / iMac) | `DisplayServices` private framework | Real backlight control. Reliable. |
| **External, DDC-capable** | DDC/CI over I2C (VCP `0x10` luminance) | Real backlight control. Apple Silicon uses `IOAVService*`; Intel uses `IOFramebuffer` I2C. |
| **Apple Studio / Pro Display XDR** | `DisplayServices` brightness | Not DDC — special-cased. |
| **Anything else / DDC broken** | Software gamma dimming (`CGSetDisplayTransferByTable`) | Darkens the image, not the backlight. Universal fallback + lets you dim *below* the panel minimum. |

**The catch:** DDC support varies by monitor, cable, and especially docks/hubs. Some
displays simply won't expose hardware brightness. Lux detects this per-display and falls
back to gamma dimming automatically, so *every* display gets a working slider even if it's
not "real" backlight control.

---

## Architecture (proposed)

- **UI:** SwiftUI `MenuBarExtra` (window style) — rich popover with sliders, schedule, macros.
- **Lifecycle:** `LSUIElement` app (no Dock icon), launch-at-login via `SMAppService`.
- **Display layer:**
  - `DisplayManager` — enumerates displays (`CGDirectDisplayID`), matches them to control services.
  - `DDCControl` — I2C read/write for external displays (per-arch).
  - `BuiltInControl` — `DisplayServices` for built-in / Apple displays.
  - `GammaControl` — software dimming fallback.
- **Automation:** `ScheduleManager` — time/sun-based rules with smooth transitions.
- **Macros:** `MacroManager` — named actions across displays; optional global hotkeys (Carbon `RegisterEventHotKey`, no special permissions).
- **Persistence:** JSON in `~/Library/Application Support/Lux/`.
- **Native interop:** a small C shim target (`CDDC`) declaring the private IOKit / DisplayServices symbols.

**Permissions footprint is light:** DDC and DisplayServices need no entitlements; hotkeys
via Carbon need none. (Ambient-light-sensor reading, if we add it, also needs none.)

---

## Roadmap (proposed, phased)

**Phase 1 — Core control**
- [x] Detect all displays; one brightness slider each in the menu bar.
- [x] DDC for external, DisplayServices for built-in, gamma fallback.
- [x] Stay in sync with outside changes (event-based for built-in via DisplayServices notifications; re-read external on open).
- [ ] Persist last-known levels; restore on launch / display reconnect.
- [x] Launch at login (`SMAppService`).

**Phase 2 — Time-based automation**
- Schedule rules → target brightness per display, with smooth ramps.
- (Optional) sunrise/sunset via location; (optional) ambient-light reactive.

**Phase 3 — Macros**  ✅ *(v1 working)*
- [x] Per-display brightness adjustments (±N%) triggered by **global hotkeys** (Carbon, no permissions).
- [x] Configured in a Settings window with a shortcut recorder; saved to disk.
- [x] Bound to a stable display key, so they survive reconnects.
- [ ] Absolute-level presets and multi-display macros.
- [ ] (Optional) contrast / input-source / volume / power via DDC.

**Phase 4 — Polish**
- Launch at login, onboarding, per-display "DDC supported?" diagnostics, app icon, signing/notarization.

---

## Build & run

Requires the Xcode toolchain (Swift 6+) and [`just`](https://github.com/casey/just)
(`brew install just`). No Apple Developer account needed for local use.

```bash
just run      # build the .app bundle (ad-hoc signed) and launch it
just          # list every recipe
```

You can also open `Package.swift` directly in Xcode to build/debug with the GUI.

### Diagnostics

```bash
just list                # enumerate displays
just get                 # read current brightness per display (read-only)
just set-brightness 0.5  # set all displays to 50%
just probe               # probe external displays for DDC support
just restore             # undo software (gamma) dimming
```

## Distribution (planned)

A one-command install, fully automated from a git tag:

1. **Build** — `just bundle` → `Lux.app` (SPM under the hood).
2. **Sign + notarize** — Developer ID signing + `notarytool`. (An Apple Developer
   account is available, so notarized builds launch with no Gatekeeper warnings.)
3. **Release** — GitHub Actions builds, signs, notarizes, and attaches `Lux.dmg`
   to a GitHub Release on each tagged version.
4. **Install** — Homebrew Cask, starting from a personal tap:

   ```bash
   brew install --cask junkai/tap/lux
   ```

   Graduate to the official `homebrew/cask` (`brew install --cask lux`) once the
   project is established.

**License:** MIT (proposed — Apache-2.0 or GPL-3.0 also on the table).

---

## Open decisions

Still to settle (they shape the Phase 2/3 data model — not blocking Phase 1):

1. **Time automation style** — fixed schedule, sun-based ramp, ambient-reactive, or none.
2. **Macro power** — brightness presets only, or full monitor control / sequences / hotkeys.

_Resolved: language (Swift), build setup (SPM)._

---

## Prior art & credit

Technical approach informed by [MonitorControl](https://github.com/MonitorControl/MonitorControl)
and `m1ddc` — the reference implementations for DDC/CI on macOS. Lux's focus is the
automation + macro layer on top of solid multi-display control.
