import XCTest
@testable import PapelimCore

final class SnippetCodableTests: XCTestCase {
    func testRoundTrip() throws {
        let snip = Snippet(
            title: "Roundtrip",
            group: "demo",
            tags: ["a", "b"],
            blocks: [
                SnippetBlock(title: "first", language: "swift", content: "let x = 1"),
                SnippetBlock(title: "second", language: "bash", content: "echo done"),
            ]
        )
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let data = try enc.encode(snip)
        let back = try dec.decode(Snippet.self, from: data)
        XCTAssertEqual(back.id, snip.id)
        XCTAssertEqual(back.title, snip.title)
        XCTAssertEqual(back.group, snip.group)
        XCTAssertEqual(back.tags, snip.tags)
        XCTAssertEqual(back.blocks.count, 2)
        XCTAssertEqual(back.blocks[0].content, "let x = 1")
        XCTAssertEqual(back.blocks[1].language, "bash")
    }

    func testFileNameUsesUUID() {
        let id = UUID()
        let snip = Snippet(id: id)
        XCTAssertEqual(snip.fileName, "\(id.uuidString).json")
    }

    func testDefaultValues() {
        let s = Snippet()
        XCTAssertEqual(s.title, "Untitled")
        XCTAssertNil(s.group)
        XCTAssertTrue(s.tags.isEmpty)
        XCTAssertEqual(s.blocks.count, 1)
        XCTAssertEqual(s.primaryLanguage, "plaintext")
    }

    func testEmptyBlocksNormalisedToSingleBlock() {
        let s = Snippet(blocks: [])
        XCTAssertEqual(s.blocks.count, 1)
    }

    func testPrimaryLanguageUsesFirstBlock() {
        let s = Snippet(blocks: [
            SnippetBlock(language: "rust"),
            SnippetBlock(language: "bash"),
        ])
        XCTAssertEqual(s.primaryLanguage, "rust")
    }

    func testUsesLanguageMatchesAnyBlock() {
        let s = Snippet(blocks: [
            SnippetBlock(language: "rust"),
            SnippetBlock(language: "bash"),
        ])
        XCTAssertTrue(s.usesLanguage("bash"))
        XCTAssertTrue(s.usesLanguage("rust"))
        XCTAssertFalse(s.usesLanguage("python"))
    }
}
