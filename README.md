# Lux

[![CI](https://github.com/yipjunkai/lux/actions/workflows/verify.yml/badge.svg)](https://github.com/yipjunkai/lux/actions/workflows/verify.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/yipjunkai/lux/badge)](https://scorecard.dev/viewer/?uri=github.com/yipjunkai/lux)
[![Release](https://img.shields.io/github/v/release/yipjunkai/lux?sort=semver)](https://github.com/yipjunkai/lux/releases)
[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](#license)

A native macOS menu bar app for controlling the brightness of **all your displays** —
built-in and external — with time-based automation and custom macro buttons.

> **Status:** 🟢 Phase 1 complete (real backlight control on every display, live
> sync with the brightness keys, launch-at-login) and **Phase 3 macros v1** working
> (per-display ±N% buttons, configured in a Settings window and saved to disk).
> Macros are triggered by **global hotkeys**. Next: automation (Phase 2).
>
> **Locked:** native **Swift** (SwiftUI + AppKit), **Swift Package Manager**, targeting
> Apple Silicon / macOS 14+. Open-source (dual **MIT OR Apache-2.0**), distributed as a
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

## Project structure

```text
lux/
├── Package.swift                       # SPM manifest — executable target, macOS 14+
├── Info.plist                          # LSUIElement (menu bar app, no Dock icon)
├── justfile                            # build / run / diagnostics recipes
├── Sources/Lux/
│   ├── main.swift                      # entry point + CLI diagnostic flags
│   ├── App/                            # lifecycle
│   │   ├── AppDelegate.swift           #   menu bar setup + wiring
│   │   ├── LoginItem.swift             #   launch-at-login (SMAppService)
│   │   └── SettingsWindowController.swift
│   ├── Displays/                       # display enumeration + brightness control
│   │   ├── DisplayManager.swift        #   enumerate displays, match to control services
│   │   ├── DisplayController.swift     #   per-display coordination
│   │   ├── BrightnessController.swift  #   unified brightness entry point
│   │   ├── DDC.swift                   #   DDC/CI VCP codes over I2C
│   │   ├── DDCManager.swift            #   per-arch I2C transport (IOAVService / IOFramebuffer)
│   │   ├── BuiltInBrightness.swift     #   DisplayServices (built-in / Apple displays)
│   │   └── GammaDimmer.swift           #   software gamma-dimming fallback
│   ├── Macros/                         # global-hotkey macros
│   │   ├── HotkeyManager.swift         #   Carbon RegisterEventHotKey (no permissions)
│   │   ├── Macro.swift                 #   model
│   │   └── MacroStore.swift            #   JSON persistence
│   └── UI/                             # SwiftUI
│       ├── RootView.swift              #   menu bar popover (sliders, macros)
│       ├── SettingsView.swift          #   macro configuration
│       └── ShortcutRecorder.swift      #   hotkey capture
└── .github/                            # CI, security policy, issue/PR templates
```

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

## Distribution

Releases are automated from Conventional Commits:

1. **Version** — [release-please](.github/workflows/release-please.yml) maintains a
   release PR; merging it bumps the version (`Info.plist`, `CHANGELOG.md`), tags
   `vX.Y.Z`, and cuts a GitHub Release.
2. **Build + sign** — the tag triggers [`release.yml`](.github/workflows/release.yml):
   a universal `Lux.app` is Developer-ID signed, notarized (`notarytool`), stapled,
   packaged as `Lux-<version>.dmg` with `checksums.txt`, and attached to the Release.
3. **Publish** — the same workflow bumps the Homebrew Cask in
   [`yipjunkai/homebrew-lux`](https://github.com/yipjunkai/homebrew-lux).
4. **Install:**

   ```bash
   brew install --cask yipjunkai/lux/lux
   ```

   (Graduate to the official `homebrew/cask` once the project is established.)

### One-time setup

The pipeline stays dormant until these repo secrets exist — the workflows no-op or
fail loudly with a clear message until then:

- **release-please** — a GitHub App (contents + pull-requests: write) exposed as
  `RELEASE_PLEASE_APP_ID` / `RELEASE_PLEASE_APP_KEY`. Using an App rather than the
  default token is what lets the release tag trigger `release.yml`.
- **Signing / notarization** — `MACOS_CERTIFICATE_P12_BASE64`,
  `MACOS_CERTIFICATE_PASSWORD`, `MACOS_SIGNING_IDENTITY`, `MACOS_NOTARY_KEY_BASE64`,
  `MACOS_NOTARY_KEY_ID`, `MACOS_NOTARY_ISSUER_ID`.

---

## Open decisions

Still to settle (they shape the Phase 2/3 data model — not blocking Phase 1):

1. **Time automation style** — fixed schedule, sun-based ramp, ambient-reactive, or none.
2. **Macro power** — brightness presets only, or full monitor control / sequences / hotkeys.

_Resolved: language (Swift), build setup (SPM), license (dual **MIT OR Apache-2.0**)._

---

## Prior art & credit

Technical approach informed by [MonitorControl](https://github.com/MonitorControl/MonitorControl)
and `m1ddc` — the reference implementations for DDC/CI on macOS. Lux's focus is the
automation + macro layer on top of solid multi-display control.

---

## License

Dual-licensed under [MIT](LICENSE-MIT) or [Apache 2.0](LICENSE-APACHE), at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in **Lux** by you, as defined in the Apache-2.0 license, shall be
dually licensed as above, without any additional terms or conditions.
