# Security Policy

## Supported versions

Lux is solo-maintained: only the **latest released minor version** receives
security fixes. Older minors are not patched — upgrade to the most recent
[release][rel] before reporting.

[rel]: https://github.com/yipjunkai/lux/releases/latest

## Reporting a vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Use GitHub's private security advisory mechanism:

1. Go to <https://github.com/yipjunkai/lux/security/advisories>
2. Click "Report a vulnerability"
3. Fill in the form with as much detail as you can share

Acknowledgement is targeted within 72 hours. There is no separate email contact
at this stage; the GitHub advisory channel is the only supported route.

## What to report

Lux talks directly to display hardware and uses private system frameworks, so
the security-relevant surface is the native/hardware layer rather than a network
boundary — Lux makes no network calls and has no third-party runtime dependencies.

- **Memory safety in the DDC/IOKit layer** — crafted EDID or DDC/CI (I2C)
  responses that trigger out-of-bounds reads/writes, panics, or unbounded
  allocations in the code that parses display metadata or talks to
  `IOAVService` / `IOFramebuffer`.
- **Untrusted persisted state** — the macro/config JSON under
  `~/Library/Application Support/Lux/`: a crafted file that causes a crash, path
  traversal, or code execution when loaded.
- **Privilege / integrity** — anything that lets Lux (which ships with no special
  entitlements) perform an action it shouldn't, or a problem with the integrity,
  notarization, or build provenance of a released `.app` / `.dmg`.
- **Supply chain** — a compromise vector in the release pipeline or the Homebrew
  cask that would ship a tampered binary.

## What is not in scope

- A display that doesn't support hardware DDC brightness — open a
  [display-compatibility report](https://github.com/yipjunkai/lux/issues/new?template=display_compat.yml) instead
- Gamma / overlay dimming looking different from real backlight control (expected — it is the fallback)
- Feature requests
- Performance or UI issues (open a regular bug report)
