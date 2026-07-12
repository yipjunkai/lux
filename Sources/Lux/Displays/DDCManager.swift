import CoreGraphics
import Foundation

/// Stateful layer over `DDC`: caches each external display's AV service and its
/// brightness range, and coalesces rapid writes. DDC over I2C is slow (tens of ms
/// per message), so writing on every slider tick would lag — instead we remember
/// the latest target per display and flush at most once per ~25ms on a background
/// queue, which keeps the UI smooth and the panel responsive.
final class DDCManager {
    static let shared = DDCManager()

    private struct Entry {
        let ref: CFTypeRef
        let maxValue: UInt16
        var currentFraction: Double
    }

    private var entries: [CGDirectDisplayID: Entry] = [:]
    private var pending: [CGDirectDisplayID: UInt16] = [:]
    private var flushScheduled = false
    private let writeQueue = DispatchQueue(label: "app.lux.ddc.write")

    /// Re-scan AV services and read each external display's current/max brightness.
    /// Call at launch and whenever the display layout changes.
    func refresh(displays: [DisplayInfo]) {
        guard DDC.isSupported else {
            entries.removeAll()
            return
        }
        let services = DDC.discoverServices()
        var next: [CGDirectDisplayID: Entry] = [:]
        for display in displays where !display.isBuiltin {
            guard let ref = DDC.service(for: display, in: services),
                let (current, maxValue) = DDC.readVCP(ref, code: 0x10), maxValue > 0
            else { continue }
            next[display.id] = Entry(
                ref: ref,
                maxValue: maxValue,
                currentFraction: Double(current) / Double(maxValue)
            )
        }
        entries = next
    }

    /// Whether DDC can control this display.
    func controls(_ id: CGDirectDisplayID) -> Bool { entries[id] != nil }

    /// Last-known brightness in 0...1, if we control this display.
    func brightness(_ id: CGDirectDisplayID) -> Double? { entries[id]?.currentFraction }

    /// Set brightness in 0...1. The actual I2C write is coalesced.
    @discardableResult
    func setBrightness(_ value: Double, for id: CGDirectDisplayID) -> Bool {
        guard var entry = entries[id] else { return false }
        let clamped = max(0, min(1, value))
        entry.currentFraction = clamped
        entries[id] = entry
        pending[id] = UInt16((Double(entry.maxValue) * clamped).rounded())
        scheduleFlush()
        return true
    }

    private func scheduleFlush() {
        guard !flushScheduled else { return }
        flushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) { [weak self] in
            self?.flush()
        }
    }

    private func flush() {
        flushScheduled = false
        let batch = pending
        pending.removeAll()
        let refs = entries
        writeQueue.async {
            for (id, value) in batch {
                guard let ref = refs[id]?.ref else { continue }
                DDC.writeVCP(ref, code: 0x10, value: value)
            }
        }
    }
}
