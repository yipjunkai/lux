import CoreGraphics
import Foundation
import IOKit

/// DDC/CI control for external displays on Apple Silicon.
///
/// macOS has no public API for external-monitor brightness, so we talk to the
/// panel over I2C using the private `IOAVService` functions — resolved at runtime
/// via `dlsym` (no link against private symbols, degrades gracefully if absent).
/// Brightness is VCP feature `0x10` in the MCCS standard.
///
/// The fiddly part is mapping a `CGDirectDisplayID` to the right `IOAVService`:
/// we enumerate `DCPAVServiceProxy` nodes in the IORegistry, read each one's
/// location + the display's product attributes, and correlate.
enum DDC {

    // MARK: Runtime bindings to the private IOAVService API

    private typealias CreateWithServiceFn =
        @convention(c) (CFAllocator?, io_service_t) -> Unmanaged<CFTypeRef>?
    private typealias WriteI2CFn =
        @convention(c) (CFTypeRef, UInt32, UInt32, UnsafeMutableRawPointer?, UInt32) -> IOReturn
    private typealias ReadI2CFn =
        @convention(c) (CFTypeRef, UInt32, UInt32, UnsafeMutableRawPointer?, UInt32) -> IOReturn

    private static let image = dlopen(nil, RTLD_NOW)
    private static let createWithService = sym(
        "IOAVServiceCreateWithService", CreateWithServiceFn.self)
    private static let writeI2CFn = sym("IOAVServiceWriteI2C", WriteI2CFn.self)
    private static let readI2CFn = sym("IOAVServiceReadI2C", ReadI2CFn.self)

    private static func sym<T>(_ name: String, _ type: T.Type) -> T? {
        guard let s = dlsym(image, name) else { return nil }
        return unsafeBitCast(s, to: type)
    }

    /// Whether the private API resolved on this system.
    static var isSupported: Bool {
        createWithService != nil && writeI2CFn != nil && readI2CFn != nil
    }

    // MARK: Service discovery

    struct AVService {
        let ref: CFTypeRef
        let location: String
        let vendorID: Int?
        let productID: Int?
        let serial: Int?
    }

    /// Build an `IOAVService` for every DCP AV proxy in the IORegistry.
    static func discoverServices() -> [AVService] {
        guard let createWithService else { return [] }
        var out: [AVService] = []

        var iterator = io_iterator_t()
        let matching = IOServiceMatching("DCPAVServiceProxy")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS
        else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            let location = stringProperty(entry, "Location") ?? "Unknown"
            let attrs = productAttributes(entry)
            if let unmanaged = createWithService(kCFAllocatorDefault, entry) {
                out.append(
                    AVService(
                        ref: unmanaged.takeRetainedValue(),
                        location: location,
                        vendorID: attrs?.vendor,
                        productID: attrs?.product,
                        serial: attrs?.serial
                    ))
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
        return out
    }

    /// Best-effort match of a display to its AV service.
    static func service(for display: DisplayInfo, in services: [AVService]) -> CFTypeRef? {
        let externals = services.filter { $0.location.localizedCaseInsensitiveContains("external") }
        if let exact = externals.first(where: {
            $0.vendorID.map { UInt32($0) } == display.vendor
                && $0.productID.map { UInt32($0) } == display.model
        }) {
            return exact.ref
        }
        // Fallback for the common single-external-monitor case.
        if externals.count == 1 { return externals.first?.ref }
        return nil
    }

    // MARK: VCP read / write (brightness = 0x10)

    /// Read a VCP feature, returning (current, max), or nil if unsupported.
    static func readVCP(_ service: CFTypeRef, code: UInt8, attempts: Int = 4) -> (
        current: UInt16, max: UInt16
    )? {
        guard let writeI2CFn, let readI2CFn else { return nil }
        var request: [UInt8] = [0x82, 0x01, code, 0]
        request[3] = 0x6e ^ 0x51 ^ request[0] ^ request[1] ^ request[2]

        for _ in 0..<attempts {
            _ = request.withUnsafeMutableBytes {
                writeI2CFn(service, 0x37, 0x51, $0.baseAddress, UInt32($0.count))
            }
            usleep(40_000)
            var reply = [UInt8](repeating: 0, count: 11)
            let ok = reply.withUnsafeMutableBytes {
                readI2CFn(service, 0x37, 0x00, $0.baseAddress, UInt32($0.count)) == kIOReturnSuccess
            }
            if ok {
                // MCCS reply lays out max at [6,7] and current at [8,9].
                let maxV = UInt16(reply[6]) << 8 | UInt16(reply[7])
                let curV = UInt16(reply[8]) << 8 | UInt16(reply[9])
                if maxV != 0 { return (curV, maxV) }
            }
            usleep(40_000)
        }
        return nil
    }

    /// Write a VCP feature value (e.g. brightness 0...max).
    @discardableResult
    static func writeVCP(_ service: CFTypeRef, code: UInt8, value: UInt16) -> Bool {
        guard let writeI2CFn else { return false }
        let hi = UInt8(value >> 8)
        let lo = UInt8(value & 0xFF)
        var data: [UInt8] = [0x84, 0x03, code, hi, lo, 0]
        data[5] = 0x6e ^ 0x51 ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4]
        let ret = data.withUnsafeMutableBytes {
            writeI2CFn(service, 0x37, 0x51, $0.baseAddress, UInt32($0.count))
        }
        return ret == kIOReturnSuccess
    }

    // MARK: IORegistry helpers

    private static func stringProperty(_ entry: io_registry_entry_t, _ key: String) -> String? {
        guard
            let raw = IORegistryEntryCreateCFProperty(
                entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        else {
            return nil
        }
        return raw as? String
    }

    private static func productAttributes(_ entry: io_registry_entry_t) -> (
        vendor: Int?, product: Int?, serial: Int?
    )? {
        let options = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        guard
            let raw = IORegistryEntrySearchCFProperty(
                entry, kIOServicePlane, "DisplayAttributes" as CFString, kCFAllocatorDefault,
                options),
            let dict = raw as? [String: Any],
            let product = dict["ProductAttributes"] as? [String: Any]
        else {
            return nil
        }
        let vendor =
            (product["LegacyManufacturerID"] as? Int) ?? (product["ManufacturerID"] as? Int)
        let productID = product["ProductID"] as? Int
        let serial = product["SerialNumber"] as? Int
        return (vendor, productID, serial)
    }
}
