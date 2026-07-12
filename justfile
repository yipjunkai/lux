# Lux — task runner.  Install with:  brew install just
# Run `just` with no arguments to see every recipe.

app        := "Lux"
bundle_id  := "com.junkai.lux"
config     := "release"

# List available recipes
default:
    @just --list

# Compile the SPM product (debug)
build:
    swift build

# Run the test suite
test:
    swift test

# Check formatting with swift-format (CI runs this — must pass)
lint:
    swift format lint --strict --recursive Sources Tests

# Auto-format the code in place
format:
    swift format --in-place --recursive Sources Tests

# Assemble Lux.app (ad-hoc signed) — the menu bar app bundle
bundle:
    #!/usr/bin/env bash
    set -euo pipefail
    swift build -c {{config}}
    bin="$(swift build -c {{config}} --show-bin-path)/{{app}}"
    app_dir="build/{{app}}.app"
    rm -rf "$app_dir"
    mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
    cp "$bin" "$app_dir/Contents/MacOS/{{app}}"
    cp Info.plist "$app_dir/Contents/Info.plist"
    codesign --force --sign - "$app_dir" >/dev/null 2>&1 || true
    echo "Built $app_dir"

# Build the bundle and launch it (look for the ☀️ in the menu bar)
run: bundle
    open "build/{{app}}.app"

# Install into /Applications — a stable location for launch-at-login
install: bundle
    rm -rf "/Applications/{{app}}.app"
    cp -R "build/{{app}}.app" "/Applications/{{app}}.app"
    @echo "Installed /Applications/{{app}}.app"

# --- Diagnostics (run straight from SPM, no bundle needed) ---

# Enumerate displays
list:
    swift run {{app}} --list-displays

# Read current brightness per display (read-only)
get:
    swift run {{app}} --get-brightness

# Set all displays to a level in 0..1, e.g. `just set-brightness 0.5`
set-brightness value:
    swift run {{app}} --set-brightness {{value}}

# Probe external displays for DDC support
probe:
    swift run {{app}} --probe-ddc

# Verify the write path with zero visible change
selftest:
    swift run {{app}} --selftest-set

# Undo software (gamma) dimming
restore:
    swift run {{app}} --restore

# Remove build artifacts
clean:
    rm -rf .build build
