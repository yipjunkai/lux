import SwiftUI

/// Sections in the Settings sidebar. Add cases here as the app grows.
enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case macros, general

    var id: String { rawValue }
    var title: String { self == .macros ? "Macros" : "General" }
    var icon: String { self == .macros ? "command" : "gearshape" }
}

/// Settings window: left sidebar + right detail (resizable).
struct SettingsView: View {
    @State private var section: SettingsSection = .macros

    var body: some View {
        NavigationSplitView {
            List(selection: $section) {
                ForEach(SettingsSection.allCases) { s in
                    Label(s.title, systemImage: s.icon).tag(s)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(180)
        } detail: {
            switch section {
            case .macros: MacrosSettingsView()
            case .general: GeneralSettingsView()
            }
        }
        .padding(16)
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity)
    }
}

// MARK: - Macros

private struct MacrosSettingsView: View {
    @ObservedObject private var store = MacroStore.shared
    @ObservedObject private var controller = DisplayController.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Macros").font(.title2).fontWeight(.semibold)
                Text("Adjust a display's brightness with a global keyboard shortcut.")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 14)

            if store.macros.isEmpty {
                Spacer()
                Text("No macros yet.\nAdd one to bind a brightness change to a hotkey.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(store.macros) { MacroCard(macro: $0) }
                    }
                    .padding(.bottom, 4)
                }
            }

            Divider().padding(.vertical, 10)

            HStack {
                Button { addMacro() } label: { Label("Add Macro", systemImage: "plus") }
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func addMacro() {
        let target = controller.items.first
        store.add(Macro(
            displayKey: target?.info.stableKey ?? "",
            displayName: target?.info.name ?? "Display",
            step: -0.10
        ))
    }
}

/// One editable macro card: display target, a single signed-step control whose
/// glyph + color + sign all encode direction, and a global-hotkey recorder.
/// No name field — the macro is defined by what it does.
private struct MacroCard: View {
    @ObservedObject private var store = MacroStore.shared
    @ObservedObject private var controller = DisplayController.shared
    let macro: Macro

    private var current: Macro { store.macros.first { $0.id == macro.id } ?? macro }

    // Direction derived purely from the sign of `step`.
    private var directionSymbol: String {
        if current.step > 0 { return "sun.max.fill" }   // brighten
        if current.step < 0 { return "moon.fill" }      // dim
        return "circle"                                 // no-op
    }
    private var directionTint: Color {
        if current.step == 0 { return .secondary }
        return current.step > 0 ? .yellow : .indigo
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            captioned("Display") {
                Picker("", selection: displayKeyBinding) {
                    ForEach(controller.items) { item in
                        Label(item.info.name,
                              systemImage: item.info.isBuiltin ? "laptopcomputer" : "display")
                            .tag(item.info.stableKey)
                    }
                    if !controller.items.contains(where: { $0.info.stableKey == current.displayKey }) {
                        Text("\(current.displayName) (off)").tag(current.displayKey)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .frame(width: 180, alignment: .leading)

            captioned("Change") {
                Stepper(value: stepBinding, in: -0.9...0.9, step: 0.05) {
                    HStack(spacing: 6) {
                        Image(systemName: directionSymbol)
                            .foregroundStyle(directionTint)
                            .frame(width: 16)
                        Text(current.signedPercent)
                            .font(.body.monospacedDigit())
                            .fontWeight(.medium)
                            .foregroundStyle(directionTint)
                            .frame(width: 52, alignment: .leading)
                            .contentTransition(.numericText())
                    }
                    .animation(.snappy(duration: 0.15), value: current.step)
                }
                .fixedSize()
            }
            .frame(width: 110, alignment: .leading)

            captioned("Shortcut") {
                ShortcutRecorder(shortcut: current.shortcut) { newShortcut in
                    var m = current
                    m.shortcut = newShortcut
                    store.update(m)
                }
            }
            .frame(width: 140, alignment: .leading)

            Spacer(minLength: 8)

            Button(role: .destructive) { store.remove(macro) } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .frame(maxHeight: .infinity, alignment: .center) // vertically centered in the card
            .help("Delete macro")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
    }

    /// A caption above each control — the System-Settings scan pattern.
    @ViewBuilder
    private func captioned<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var stepBinding: Binding<Double> {
        Binding(get: { current.step }, set: {
            var m = current
            m.step = $0
            store.update(m)
        })
    }

    private var displayKeyBinding: Binding<String> {
        Binding(get: { current.displayKey }, set: { key in
            var m = current
            m.displayKey = key
            m.displayName = controller.items.first { $0.info.stableKey == key }?.info.name ?? m.displayName
            store.update(m)
        })
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General").font(.title2).fontWeight(.semibold)

            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { on in
                    LoginItem.setEnabled(on)
                    launchAtLogin = LoginItem.isEnabled
                }
            )) {
                Text("Launch at login")
            }
            .toggleStyle(.switch)

            if LoginItem.needsApproval {
                Button("Approve in System Settings…") { LoginItem.openSettings() }
                    .buttonStyle(.link)
                    .font(.caption)
            }

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                Text("Lux").font(.headline)
                Text("Native menu bar brightness control · v0.1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { launchAtLogin = LoginItem.isEnabled }
    }
}
