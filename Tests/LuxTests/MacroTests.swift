import XCTest

@testable import Lux

/// Pure-logic tests for the `Macro` model — no hardware, no filesystem.
final class MacroTests: XCTestCase {
    func testDeltaEqualsStep() {
        let m = Macro(displayKey: "k", displayName: "Display", step: -0.25)
        XCTAssertEqual(m.delta, -0.25, accuracy: 1e-9)
    }

    func testSignedPercentRendersSignAndMagnitude() {
        let up = Macro(displayKey: "k", displayName: "Display", step: 0.10)
        XCTAssertEqual(up.signedPercent, "+10%")

        // A negative step must render with a leading minus, never a '+'.
        let down = Macro(displayKey: "k", displayName: "Display", step: -0.10)
        XCTAssertFalse(down.signedPercent.hasPrefix("+"))
        XCTAssertTrue(down.signedPercent.hasSuffix("10%"))
    }

    func testSignedPercentRoundsMagnitude() {
        let m = Macro(displayKey: "k", displayName: "Display", step: 0.156)
        XCTAssertEqual(m.signedPercent, "+16%")
    }

    func testCodableRoundTripPreservesEverything() throws {
        let original = Macro(
            displayKey: "vendor-model-serial",
            displayName: "Studio Display",
            step: 0.15,
            shortcut: .init(keyCode: 126, modifiers: 256, label: "↑")
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Macro.self, from: data)
        // Equatable includes the id, so a faithful round-trip must compare equal.
        XCTAssertEqual(original, decoded)
    }
}
