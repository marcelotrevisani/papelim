@testable import PapelimCore
import XCTest

final class StorageLocationTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let loc = StorageLocation(name: "iCloud", rawPath: "/tmp/foo", enabled: false)
        let enc = JSONEncoder()
        let dec = JSONDecoder()
        let data = try enc.encode(loc)
        let back = try dec.decode(StorageLocation.self, from: data)
        XCTAssertEqual(back, loc)
    }

    func testDefaultEnabledIsTrue() {
        let loc = StorageLocation(name: "x", rawPath: "/tmp/x")
        XCTAssertTrue(loc.enabled)
    }

    func testUrlMatchesRawPath() {
        let loc = StorageLocation(name: "x", rawPath: "/tmp/papelim-test")
        XCTAssertEqual(loc.url.path, "/tmp/papelim-test")
    }

    func testDetectDoesNotCrashWithEmptyHome() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty-home-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let detected = SuggestedLocations.detect(home: tmp)
        XCTAssertTrue(detected.isEmpty, "No sync dirs present → should detect nothing")
    }

    func testDetectPicksUpDocuments() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("fake-home-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tmp.appendingPathComponent("Documents"),
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tmp) }
        let detected = SuggestedLocations.detect(home: tmp)
        XCTAssertTrue(detected.contains { $0.name == "Local" })
    }
}
