# Contributing to Lux

Thanks for your interest. Lux is solo-maintained — clear, focused contributions
help enormously. Issues and pull requests are the primary inbound channels.

## Quick start

```bash
git clone https://github.com/yipjunkai/lux
cd lux

# Build the Lux.app bundle (ad-hoc signed) and launch it — look for ☀️ in the menu bar
just run
```

Required toolchain:

- **Xcode toolchain (Swift 6+)** — Lux is native Swift (SwiftUI + AppKit), built with Swift Package Manager
- [`just`](https://github.com/casey/just) — the command runner used by every recipe (`brew install just`)

Lux targets **macOS 14+, Apple Silicon**. No Apple Developer account is needed
for local development. You can also open `Package.swift` directly in Xcode.

## Development recipes

```bash
just              # list every recipe
just build        # compile the SPM product (debug)
just run          # build the .app bundle and launch it
just list         # enumerate displays
just get          # read current brightness per display (read-only)
just probe        # probe external displays for DDC support
just restore      # undo software (gamma) dimming
```

> `just lint` (swift-format) and `just test` recipes land alongside the CI
> workflow. Until then, verify a change by building it and exercising it on real
> hardware (see the checklist below).

## Pull request checklist

- [ ] `just build` compiles cleanly
- [ ] If touching the **display layer** (DDC / DisplayServices / gamma): tested on
      real hardware — ideally a built-in panel *and* at least one external display —
      and confirmed brightness still moves (or falls back to gamma) without artifacts
- [ ] If touching **macros / hotkeys**: verified the hotkey registers, fires, and
      survives a display disconnect/reconnect
- [ ] `README.md` updated if behavior, recipes, or the roadmap changed
- [ ] Commits follow Conventional Commits (see below)

## Commit style

Lux uses [Conventional Commits](https://www.conventionalcommits.org/)
(`feat:` / `fix:` / `docs:` / `chore:` / `perf:` / `refactor:` / `test:`).
`release-please` parses these to generate `CHANGELOG.md` and choose the next
version bump, so following the convention is what surfaces your change in the
release notes. Use a `BREAKING CHANGE:` footer (or `!` after the type) for
anything that changes behavior users rely on.

## Style

- Swift: match the surrounding code; the `swift-format` config is enforced by CI once it lands.
- Keep the hardware / IOKit layer defensive — displays, cables, and docks vary wildly, and a
  misbehaving monitor must never crash the app (fall back to gamma, log, and move on).

## License

By contributing you agree that your contributions are dual-licensed under
[MIT](LICENSE-MIT) or [Apache 2.0](LICENSE-APACHE), matching the project license.
