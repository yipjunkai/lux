import Combine
import Foundation

/// Persists the user's macros as JSON in Application Support, and re-registers
/// their global hotkeys whenever they change.
@MainActor
final class MacroStore: ObservableObject {
    static let shared = MacroStore()

    @Published private(set) var macros: [Macro] = []

    private let fileURL: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lux", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("macros.json")
    }()

    init() { load() }

    func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Macro].self, from: data) {
            macros = decoded
        }
        HotkeyManager.shared.reload(macros)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(macros) {
            try? data.write(to: fileURL, options: .atomic)
        }
        HotkeyManager.shared.reload(macros)
    }

    func add(_ macro: Macro) { macros.append(macro); persist() }

    func remove(_ macro: Macro) {
        macros.removeAll { $0.id == macro.id }
        persist()
    }

    func update(_ macro: Macro) {
        guard let idx = macros.firstIndex(where: { $0.id == macro.id }) else { return }
        macros[idx] = macro
        persist()
    }
}
