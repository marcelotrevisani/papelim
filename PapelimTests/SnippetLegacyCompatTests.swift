import XCTest
@testable import PapelimCore

/// Old on-disk JSON (written before we added fontSize/useSerifFont/renderMarkdown)
/// must continue to decode into the current Snippet struct.
final class SnippetLegacyCompatTests: XCTestCase {

    func testLegacySnippetWithoutNewBlockFieldsDecodes() throws {
        let id = UUID().uuidString
        let blockId = UUID().uuidString
        let legacy = """
        {
            "id": "\(id)",
            "title": "legacy snippet",
            "tags": ["a", "b"],
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-02T00:00:00Z",
            "blocks": [
                {
                    "id": "\(blockId)",
                    "title": "",
                    "language": "bash",
                    "content": "echo hi"
                }
            ]
        }
        """.data(using: .utf8)!
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let snip = try dec.decode(Snippet.self, from: legacy)
        XCTAssertEqual(snip.title, "legacy snippet")
        XCTAssertEqual(snip.tags, ["a", "b"])
        XCTAssertNil(snip.group)
        XCTAssertEqual(snip.blocks.count, 1)
        XCTAssertEqual(snip.blocks[0].content, "echo hi")
        XCTAssertNil(snip.blocks[0].fontSize)
    }

    func testCurrentSnippetJSONIsForwardsCompatible() throws {
        // Encode with the new schema, decode back — should be lossless.
        let original = Snippet(
            title: "t",
            group: "g",
            blocks: [
                SnippetBlock(language: "markdown",
                             content: "# hi",
                             fontSize: 20,
                             fontFamily: "Helvetica",
                             renderMarkdown: true),
            ]
        )
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let data = try enc.encode(original)
        let back = try dec.decode(Snippet.self, from: data)
        XCTAssertEqual(back.group, "g")
        XCTAssertEqual(back.blocks[0].fontSize, 20)
        XCTAssertEqual(back.blocks[0].fontFamily, "Helvetica")
        XCTAssertTrue(back.blocks[0].renderMarkdown)
    }
}
