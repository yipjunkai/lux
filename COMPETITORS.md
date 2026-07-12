# Competitive Analysis — macOS display-brightness apps

> Research pass for **Lux**. 30 apps surveyed → 19 real competitors, plus a
> prioritized feature-gap analysis against Lux's current feature set.
> _Generated 2026-07-01 via a multi-agent web-research sweep._

---

## TL;DR

- The category splits into **full display suites** (BetterDisplay, Lunar), **open-source DDC** (MonitorControl), **paid DDC menu-bar tools** (DisplayBuddy, TeenyDisplay), **XDR/HDR boosters** (Vivid, BrightIntosh, TotalXDR), and **color-temp / software-dimmer** utilities (f.lux, GammaDimmer, etc.).
- Recurring **paid** features across the leaders: adaptive/scheduled brightness, XDR boost, sub-zero dimming, presets, DDC input/volume, Shortcuts/CLI automation.
- **Lux's lane:** the lightweight, **keyboard-first, open-source** option — real per-display backlight control driven by global hotkeys, free, installable via Homebrew.
- **Top next feature:** absolute-level **presets bound to hotkeys** (lowest effort, high value, even BetterDisplay lacks it, and it's the foundation for scheduling).

---

## Competitor landscape

### Full display suites (the heavyweights)

#### BetterDisplay — <https://betterdisplay.pro>
- **Pricing:** Freemium. Substantial free tier (DDC brightness/volume/input/power, software dimming). Pro is a one-time **$21.99 / €19.99** perpetual license with 1 year of updates; 14-day Pro trial.
- **One-liner:** A power-user Swiss-army display utility — HiDPI scaling, XDR/HDR brightness upscaling to ~1600 nits, virtual screens, DDC control, and EDID overrides in one dense menu-bar app.
- **Standout:**
  - Only app offering DDC control on Apple Silicon built-in HDMI and the 2018 Mac mini HDMI port
  - Software XDR/HDR brightness boost to ~1600 nits, with nits-based normalized multi-display sync
  - Virtual/dummy displays, PIP, local streaming, and EDID override for headless/dev setups
  - Deep automation surface: Shortcuts (App Intents), CLI, URL scheme, HTTP, shell scripts

#### Lunar — <https://lunar.fyi>
- **Pricing:** Freemium. Free tier (DDC control, sub-zero dimming, CLI) capped at ~100 brightness/contrast adjustments/day. Lunar Pro is **~$23 one-time** lifetime (up to 5 Macs); 14-day Pro trial.
- **One-liner:** The de-facto power-user Mac app for adaptive external-monitor brightness: real DDC/CI control plus four distinct sensor/location/clock automation modes and an XDR unlock.
- **Standout:**
  - Four genuinely distinct adaptive modes: **Sync** (mirror built-in ALS to externals), **Sensor** (external wireless sensor), **Location** (sun position), **Clock** (schedule)
  - XDR Brightness unlock to ~1600 nits plus sub-zero dimming below the hardware minimum
  - Full DDC suite (brightness/contrast/volume/input) with gamma fallback, plus FaceLight/BlackOut
  - Deep CLI + Shortcuts automation and an auto-learning brightness curve

### Open-source DDC

#### MonitorControl — <https://github.com/MonitorControl/MonitorControl>
- **Pricing:** Free and open source (**MIT**). GitHub Releases and Homebrew (`brew install --cask monitorcontrol`). No paid tier.
- **One-liner:** The de-facto free, open-source menu-bar app that makes external displays behave like native Apple ones: hardware DDC brightness/contrast/volume with native OSD and key support.
- **Standout:**
  - Fully free and open source with a large maintained community and Homebrew distribution
  - Native macOS OSD rendering and Apple brightness/media-key hijacking so externals feel first-party
  - Multi-protocol fallback (DDC + gamma + shade) that also dims AirPlay/Sidecar/DisplayLink/virtual screens
  - Combined hardware+gamma dimming to extend brightness below the panel's hardware minimum, plus multi-display sync
- **Gaps:** no presets, no input-source switching (abandoned, issue #720), no scheduling.

#### MonitorControl Lite — Mac App Store
- **Pricing:** Free, no IAP, no data collection. Sandboxed.
- **One-liner:** A sandboxed App Store version of MonitorControl that dims purely in software (gamma/overlay) — safe and simple, but **cannot change a monitor's real backlight**.
- **Standout:** fully sandboxed (no low-level permissions), overlay dimming works for AirPlay/Sidecar/DisplayLink, custom brightness shortcuts.

### Paid DDC menu-bar tools

#### DisplayBuddy — <https://displaybuddy.app/>
- **Pricing:** One-time lifetime from **$24.99** (Mac); multi-Mac tiers. No subscription; free lifetime updates; 7-day trial. Separate Windows app.
- **One-liner:** A polished, calmer paid DDC/CI controller focused on presets, multi-display sync, schedule automation, and deep Shortcuts/Siri integration without Lunar's complexity.
- **Standout:**
  - Schedule engine tying presets to sunrise/sunset, specific times, charger status, and Dark Mode
  - UltraBright XDR boost to ~1600 nits plus multi-display sync with per-monitor Sync Offsets
  - Wi-Fi control of Samsung Smart Monitors and LG MyView displays that don't expose DDC
  - Deep macOS integration: Shortcuts, Siri, Control Center, Spotlight, widgets

#### TeenyDisplay — <https://teenydisplay.com/>
- **Pricing:** **$9.99 one-time** (3-day trial). No subscription.
- **One-liner:** A lightweight, native-feeling menu-bar DDC controller for people who want explicit sliders, shortcuts, and presets without an adaptive layer — the cheapest full-DDC paid option.
- **Standout:** full DDC brightness/contrast/volume/input; optional F1/F2 & volume-key interception; named presets + sync; `teenydisplay://` URL scheme.

### XDR / HDR brightness boosters

#### Vivid — <https://www.getvivid.app/>
- **Pricing:** One-time — single **€10**, team €40 (5), company €60 (10). No subscription. Also on Setapp.
- **One-liner:** An XDR/HDR-boost app that roughly doubles usable MacBook Pro / Pro Display XDR brightness system-wide (500 → 1000+ nits) using standard Apple HDR APIs.
- **Standout:** system-wide boost that reuses native brightness keys; Eclipse mode dims below the macOS minimum; battery automation; Splitscreen boosts only the active window.

#### BrightIntosh — <https://brightintosh.de/>
- **Pricing:** Mac App Store **$1.99** one-time, **or free & open source (GPL-3.0)** if self-built.
- **One-liner:** Open-source menu-bar app that unlocks sustained ~1000-nit XDR brightness on Apple XDR displays via gamma range shifting, with rich battery/timer automation.
- **Standout:** open-source; richest boost automation (battery, low-battery threshold, timer); user-assignable global hotkey toggle; in-app intensity slider + launch-at-login.

#### TotalXDR — <https://junebytes.com/totalxdr>
- **Pricing:** **$15 one-time** with lifetime updates; 14-day trial.
- **One-liner:** A minimalist menu-bar switch that keeps XDR/HDR extra brightness always on (~1000 nits). Also supports Intel Macs driving a Pro Display XDR.

### Color-temperature / night & circadian

#### f.lux — <https://justgetflux.com>
- **Pricing:** Free (donation-optional). Cross-platform. v42.2 (Sept 2024); development effectively stalled.
- **One-liner:** The original time-of-day color-temperature app, warming the display ~6500K → ~1200–1900K based on local sunrise/sunset.
- **Standout:** the most mature solar/circadian scheduling model; very wide warm range incl. Darkroom mode; per-app/window and quick-disable toggles; cross-platform.

#### Shifty — <https://shifty.natethompson.io>
- **Pricing:** Free & open source (GPL-3.0). Latest v1.2 (Oct 2021).
- **One-liner:** Extends Apple's built-in Night Shift with finer scheduling, a color-temp slider, per-app/website disabling, and global hotkeys.
- **Standout:** per-app / per-website Night Shift suppression; rides Apple's native Night Shift API (color-managed, not fighting gamma); global hotkeys.

#### Sundown — <https://trysundown.com>
- **Pricing:** 7-day trial, then paid (~$4.99/mo, $39/yr, or ~$79 lifetime).
- **One-liner:** A lightweight, privacy-focused blue-light app reaching an extreme 500K deep-red, dimming via gamma curves to avoid PWM flicker (clinical-grade circadian protection).
- **Standout:** PWM flicker-free gamma dimming; one of the deepest blue-light reductions (~99% blocked); anti-dithering pass for Apple Silicon banding; zero telemetry, ~400 KB.

#### Iris — <https://iristech.co>
- **Pricing:** Free trial; $15 one-time lifetime or subscription.
- **One-liner:** A feature-dense, highly configurable cross-platform blue-light + brightness tool with PWM-free brightness reduction and many reading/sleep modes.
- **Standout:** flicker-free (PWM-free) software brightness; broadest platform coverage; huge blue-light range; claims USB/docked external support via a color API.

### Software dimmers / dark overlays

#### GammaDimmer — <https://lowtechguys.com/gammadimmer/>
- **Pricing:** Free (Mac App Store). By the Lunar author.
- **One-liner:** A free software dimmer that darkens any screen via RGB gamma tables with a dark-overlay fallback, preserving color accuracy.
- **Standout:** gamma dimming keeps color more accurate than a plain overlay; auto-learned per-display curves; F1/F2 dim active display, Shift+F1/F2 all displays.

#### Brightness Slider — Mac App Store
- **Pricing:** Free (last updated 2015 — effectively abandonware).
- **One-liner:** A minimal free menu-bar brightness utility combining built-in backlight control with a dark-overlay veil; no DDC for externals.
- **Standout:** tiny footprint; overlay veil dims below hardware minimum; custom hotkeys + arrow-key adjust.

#### Shady — <https://github.com/mattgemmell/Shady>
- **Pricing:** Free & open source (build from source).
- **One-liner:** A minimalist menu-bar app that lays a dark overlay over the screen to dim far below the system minimum.
- **Standout:** dead-simple "darker than possible" overlay; multi-display + keyboard shortcuts; open source & panel-safe.

#### QuickShade — Mac App Store
- **Pricing:** Free (~4.5 MB).
- **One-liner:** A tiny free App Store overlay dimmer popular as a workaround for Mac minis / machines with broken native brightness keys.
- **Standout:** reliable brightness workaround for desktop Macs with no brightness keys; user-assignable dim up/down shortcuts.

### Focus / adjacent

#### HazeOver — <https://hazeover.com/>
- **Pricing:** Paid one-time (free trial); also on Setapp.
- **One-liner:** A "distraction dimmer" that darkens background windows to spotlight the active one — a focus overlay, not a true brightness controller.
- **Standout:** per-window focus dimming; Focus Filters integration; Shortcuts/AppleScript.

#### Nightfall — <https://github.com/r-thomson/Nightfall>
- **Pricing:** Free & open source (Swift; GitHub + App Store; actively maintained).
- **One-liner:** A minimal Swift menu-bar utility for toggling/scheduling macOS **Dark Mode** via a hotkey — adjacent, not a brightness tool.
- **Standout:** clean single-purpose Dark Mode hotkey; sunset/sunrise auto-switch; native Swift, maintained.

---

## Feature opportunities for Lux

Ranked by effort-to-value, filtered to what fits Lux's Swift / DDC-IOAVService / DisplayServices / Carbon-hotkey / menu-bar, keyboard-first architecture. **Excludes what Lux already has** (per-display DDC + built-in backlight, gamma fallback, live event-based sync, global-hotkey macros, launch-at-login).

| # | Feature | Effort | Competitors with it |
|---|---|---|---|
| ⭐ 1 | **Absolute-level presets bound to hotkeys** | 🟢 Low | Lunar, DisplayBuddy, TeenyDisplay, BetterDisplay |
| 2 | **Sync-all-displays together (linked brightness + offsets)** | 🟢 Low | MonitorControl, DisplayBuddy, Lunar, GammaDimmer, BetterDisplay |
| 3 | **DDC volume / contrast / input-source control** | 🟡 Medium | Lunar, MonitorControl, DisplayBuddy, BetterDisplay, TeenyDisplay |
| 4 | **Sub-zero / below-minimum dimming** | 🟡 Medium | Lunar, MonitorControl, Vivid, BrightIntosh, Brightness Slider, Shady, GammaDimmer |
| 5 | **Native brightness/media-key interception** | 🟡 Medium | MonitorControl, TeenyDisplay, GammaDimmer, Lunar |
| 6 | **macOS Shortcuts / App Intents + CLI** | 🟡 Medium | Lunar, BetterDisplay, DisplayBuddy, TeenyDisplay, MonitorControl |
| 7 | **Color-temp / warmth hotkey (Night Shift API)** | 🟡 Medium | f.lux, Shifty, Sundown, Iris, Lunar |
| 8 | **Time / sunrise-sunset schedule automation** | 🔴 High | Lunar, DisplayBuddy, f.lux |
| 9 | **XDR/HDR brightness boost** | 🔴 High | BetterDisplay, Lunar, Vivid, BrightIntosh, TotalXDR, DisplayBuddy |

### Details

**1. Absolute-level presets bound to hotkeys** — Save named snapshots of per-display brightness ("Day 80%", "Night 20%", "Movie") and recall instantly. Extends the existing hotkey macro model from relative ±steps to absolute set-to-N% across multiple displays.
- _Fit:_ reuses the Macro/Shortcut Carbon-hotkey model, the stableKey display binding, and MacroStore JSON almost verbatim. A preset is a macro that sets absolute multi-display values instead of a relative delta. Purely additive.
- _Differentiation:_ one of the two most-requested features BetterDisplay still lacks; Lux delivers it hotkey-first (recall by keystroke, no menu), free & open-source unlike Lunar Pro.

**2. Sync-all-displays together** — One slider/hotkey moves all displays in unison, with per-display offsets so mismatched monitors stay visually matched.
- _Fit:_ BrightnessController already drives displays independently; a sync layer fans one delta to all targets. `Shift`+hotkey = "all displays" extends the existing bare-function-key support.
- _Differentiation:_ matches MonitorControl's headline "one slider for all" and GammaDimmer's Shift+F1/F2, in a lighter package; per-display offsets echo DisplayBuddy's Sync Offsets without the paywall.

**3. DDC volume / contrast / input-source control** — Extend the DDC/IOAVService path from brightness (VCP 0x10) to volume (0x62), contrast (0x12), input source (0x60), each optionally hotkey-driven.
- _Fit:_ DDCManager already speaks VCP over IOAVService — adding control codes is incremental. Each slots into the per-display, hotkey-bindable pattern.
- _Differentiation:_ input switching is abandoned in MonitorControl (#720) and is a Lunar Pro feature — free, hotkey-driven input/contrast/volume closes the biggest gap vs. paid DDC apps.

**4. Sub-zero / below-minimum dimming** — Dim past the hardware 0% floor by layering the existing gamma dimmer (and/or overlay) on top of hardware brightness, as a continuous slider that crosses smoothly from hardware into software range.
- _Fit:_ GammaDimmer already exists as fallback; promote it to an intentional below-min extension. Main work is a unified brightness scale that hands off from DDC/DisplayServices to gamma.
- _Differentiation:_ near-universal competitor feature Lux lacks; delivered hotkey-first & open-source for the eye-strain use case.

**5. Native brightness/media-key interception** — Optionally capture the Mac's built-in brightness keys so F1/F2 adjust the focused/all external displays like a native Apple panel, with an OSD.
- _Fit:_ complements the Carbon hotkey system; Lux already registers bare function keys. Perfect keyboard-first fit — no slider needed for the common case.
- _Differentiation:_ MonitorControl's & TeenyDisplay's signature "feels first-party" behavior, matched while staying lighter and pairable with Lux's own macros.

**6. macOS Shortcuts / App Intents + CLI** — Expose brightness get/set, preset recall, and sync as Shortcuts actions (App Intents) and a small CLI, scriptable from Automator, Focus modes, Stream Deck, or shell.
- _Fit:_ App Intents is native Swift; a CLI reuses the core (Lux already has `--list-displays` etc.).
- _Differentiation:_ every serious competitor leans on Shortcuts/CLI; matching it keeps Lux credible for power users and undercuts paywalled automation.

**7. Color-temp / warmth hotkey (Night Shift API)** — Keyboard-driven warm/cool shift driving Apple's native Night Shift (CoreBrightness) API rather than gamma tables.
- _Fit:_ another bindable adjustment in the hotkey framework; Night Shift API sidesteps gamma conflicts with GammaDimmer and keeps HDR intact.
- _Differentiation:_ bundles a common night need (owned by f.lux/Shifty/Sundown) into one lightweight brightness+warmth tool; API approach is more color-safe than gamma-based rivals.

**8. Time / sunrise-sunset schedule automation** — Fire saved presets at clock times or sunrise/sunset (and optionally charger-connect or Dark Mode change).
- _Fit:_ presets provide the target state; this adds a scheduling/solar-time layer (Location + timer). Keep it lean — fire presets, not a continuous adaptive curve. Depends on feature #1.
- _Differentiation:_ top gap across BetterDisplay & MonitorControl; DisplayBuddy/Lunar charge for it. Explicitly _not_ an ambient-sensor engine — keeps Lux lightweight while covering "dim at night".

**9. XDR/HDR brightness boost** — Unlock the ~1000–1600 nit HDR range for SDR content on capable MacBook Pro / XDR panels, hotkey-toggled with optional battery-aware auto-disable.
- _Fit:_ a genuinely new subsystem (HDR-range gamma shifting / Apple HDR APIs) unrelated to Lux's DDC/DisplayServices paths, but the toggle + battery UX fit the menu-bar model. High effort, hardware-specific.
- _Differentiation:_ the single biggest paid-feature magnet in the category — a free, open-source, hotkey-toggled boost with battery automation is a strong differentiator vs. Vivid/TotalXDR/Lunar Pro.

---

## Top pick

**Absolute-level brightness presets bound to global hotkeys.** Lowest-effort, highest-leverage next step: it reuses Lux's Carbon-hotkey macro engine, stableKey binding, and JSON store almost verbatim, delivers a top-requested feature that **even BetterDisplay lacks**, does it in a uniquely hotkey-first/open-source/free package — and it's the prerequisite for scheduling (#8), since a schedule just fires a preset at a time.

## Positioning

Position Lux as the **lightweight, keyboard-first, open-source alternative** to bloated display suites: everything you can do from a keystroke, nothing you have to dig through a dense settings panel to find. Where BetterDisplay and Lunar overwhelm casual users and paywall their best features, and MonitorControl leans mouse/OSD-first, Lux owns the *"macros and hotkeys for real per-display backlight control, free and open-source, distributed via Homebrew"* niche. Grow deliberately outward from that core — **presets → sync → DDC volume/input → optional scheduling** — while explicitly declining the heavyweight ambient-sensor/adaptive-curve complexity that makes competitors feel bloated.
