import XCTest
@testable import PapelimCore

final class SnippetRepositoryTests: XCTestCase {
    var tempRoot: URL!
    var loc1: StorageLocation!
    var loc2: StorageLocation!
    var repo: SnippetRepository!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("papelim-tests-\(UUID().uuidString)", isDirectory: true)
        let a = tempRoot.appendingPathComponent("locA")
        let b = tempRoot.appendingPathComponent("locB")
        try FileManager.default.createDirectory(at: a, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        loc1 = StorageLocation(name: "A", rawPath: a.path)
        loc2 = StorageLocation(name: "B", rawPath: b.path)
        repo = SnippetRepository(locations: [loc1, loc2])
    }

    override func tearDownWithError() throws {
        if let tempRoot { try? FileManager.default.removeItem(at: tempRoot) }
    }

    func testSaveFansOutToAllEnabledLocations() throws {
        let snip = Snippet(title: "hello",
                           blocks: [SnippetBlock(language: "python", content: "print('hi')")])
        let failures = try repo.save(snip)
        XCTAssertTrue(failures.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: loc1.url.appendingPathComponent(snip.fileName).path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: loc2.url.appendingPathComponent(snip.fileName).path))
    }

    func testSaveSkipsDisabledLocations() throws {
        var disabled = loc2!
        disabled.enabled = false
        repo.setLocations([loc1, disabled])
        let snip = Snippet(title: "skip")
        try repo.save(snip)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: loc1.url.appendingPathComponent(snip.fileName).path))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: loc2.url.appendingPathComponent(snip.fileName).path))
    }

    func testLoadAllMergesAcrossLocations() throws {
        let a = Snippet(title: "only-in-A")
        let b = Snippet(title: "only-in-B")
        try write(a, to: loc1)
        try write(b, to: loc2)
        let loaded = try repo.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains { $0.title == "only-in-A" })
        XCTAssertTrue(loaded.contains { $0.title == "only-in-B" })
    }

    func testLoadAllNewestUpdatedAtWins() throws {
        let id = UUID()
        let old = Snippet(id: id, title: "old",
                          updatedAt: Date(timeIntervalSince1970: 1_000_000))
        let new = Snippet(id: id, title: "new",
                          updatedAt: Date(timeIntervalSince1970: 2_000_000))
        try write(old, to: loc1)
        try write(new, to: loc2)
        let loaded = try repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "new")
    }

    func testLoadAllIgnoresNonJsonFiles() throws {
        try "garbage".write(
            to: loc1.url.appendingPathComponent("readme.txt"),
            atomically: true, encoding: .utf8)
        let snip = Snippet(title: "real")
        try write(snip, to: loc1)
        let loaded = try repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "real")
    }

    func testLoadAllIgnoresMalformedJson() throws {
        try "{ not valid json".write(
            to: loc1.url.appendingPathComponent("\(UUID().uuidString).json"),
            atomically: true, encoding: .utf8)
        let loaded = try repo.loadAll()
        XCTAssertEqual(loaded.count, 0)
    }

    func testDeleteRemovesFromAllLocations() throws {
        let snip = Snippet(title: "doomed")
        try repo.save(snip)
        _ = repo.delete(snip)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: loc1.url.appendingPathComponent(snip.fileName).path))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: loc2.url.appendingPathComponent(snip.fileName).path))
    }

    func testDeleteIsIdempotent() throws {
        let snip = Snippet(title: "missing")
        let failures = repo.delete(snip)
        XCTAssertTrue(failures.isEmpty)
    }

    func testRoundTripPreservesBlocksAndGroup() throws {
        let snip = Snippet(
            title: "complex",
            group: "work",
            tags: ["cli", "demo"],
            blocks: [
                SnippetBlock(title: "run", language: "bash", content: "cargo run"),
                SnippetBlock(title: "main", language: "rust", content: "fn main() {}"),
            ]
        )
        try repo.save(snip)
        let loaded = try repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        let got = loaded[0]
        XCTAssertEqual(got.id, snip.id)
        XCTAssertEqual(got.group, "work")
        XCTAssertEqual(got.blocks.count, 2)
        XCTAssertEqual(got.blocks[0].content, "cargo run")
        XCTAssertEqual(got.blocks[1].language, "rust")
    }

    // MARK: - helpers
    private func write(_ snip: Snippet, to loc: StorageLocation) throws {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(snip)
        try data.write(to: loc.url.appendingPathComponent(snip.fileName))
    }
}
