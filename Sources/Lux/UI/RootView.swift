import AppKit
import SwiftUI

/// The main popover content: a live brightness slider per display, plus app
/// controls. Macros live entirely in Settings + global hotkeys, so there are no
/// macro buttons here.
struct RootView: View {
    @StateObject private var controller = DisplayController.shared
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                Text("Lux").font(.headline)
                Spacer()
                Button {
                    SettingsWindowController.shared.show()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }

            if controller.items.isEmpty {
                Text("No displays detected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(controller.items) { item in
                    DisplayRow(item: item, controller: controller)
                }
            }

            Divider()

            Toggle(
                isOn: Binding(
                    get: { launchAtLogin },
                    set: { on in
                        LoginItem.setEnabled(on)
                        launchAtLogin = LoginItem.isEnabled
                    }
                )
            ) {
                Text("Launch at login")
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .font(.callout)

            if LoginItem.needsApproval {
                Button("Approve in System Settings…") { LoginItem.openSettings() }
                    .buttonStyle(.link)
                    .font(.caption2)
            }

            HStack {
                Button {
                    controller.reload()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Spacer()
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
            .font(.callout)
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            controller.reload()
            launchAtLogin = LoginItem.isEnabled
        }
    }
}

/// One display: name, type, a live brightness slider, and which backend drives it.
private struct DisplayRow: View {
    let item: DisplayController.Item
    @ObservedObject var controller: DisplayController

    private var brightness: Binding<Double> {
        Binding(
            get: { controller.brightness(for: item.id) },
            set: { controller.set($0, for: item.id) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: item.info.isBuiltin ? "laptopcomputer" : "display")
                Text(item.info.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                Text("\(Int((controller.brightness(for: item.id) * 100).rounded()))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                Image(systemName: "sun.min").foregroundStyle(.secondary)
                Slider(value: brightness, in: 0...1) { editing in
                    if editing {
                        controller.beginDragging(item.id)
                    } else {
                        controller.endDragging(item.id)
                    }
                }
                Image(systemName: "sun.max").foregroundStyle(.secondary)
            }

            Text(backendCaption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var backendCaption: String {
        switch item.backend {
        case .backlight: return "Hardware backlight"
        case .ddc: return "DDC/CI · hardware backlight"
        case .software: return "Software dimming"
        }
    }
}
