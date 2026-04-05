@testable import PapelimCore
import XCTest

final class SnippetBlockTests: XCTestCase {
    func testDefaultsAreNil() {
        let b = SnippetBlock()
        XCTAssertNil(b.fontSize)
        XCTAssertNil(b.fontFamily)
        XCTAssertFalse(b.renderMarkdown)
    }

    func testEffectiveFontSizeDefaultsTo13() {
        XCTAssertEqual(SnippetBlock().effectiveFontSize, 13)
    }

    func testEffectiveFontSizeUsesOverride() {
        XCTAssertEqual(SnippetBlock(fontSize: 18).effectiveFontSize, 18)
    }

    func testWantsPlainTextEditorForPlaintext() {
        XCTAssertTrue(SnippetBlock(language: "plaintext").wantsPlainTextEditor)
    }

    func testWantsPlainTextEditorForMarkdown() {
        XCTAssertTrue(SnippetBlock(language: "markdown").wantsPlainTextEditor)
    }

    func testWantsPlainTextEditorFalseForCodeLanguages() {
        XCTAssertFalse(SnippetBlock(language: "rust").wantsPlainTextEditor)
        XCTAssertFalse(SnippetBlock(language: "python").wantsPlainTextEditor)
    }

    func testWantsMarkdownPreviewRequiresMarkdownLanguage() {
        let b = SnippetBlock(language: "plaintext", renderMarkdown: true)
        XCTAssertFalse(b.wantsMarkdownPreview)
    }

    func testWantsMarkdownPreviewRequiresRenderFlag() {
        let b = SnippetBlock(language: "markdown", renderMarkdown: false)
        XCTAssertFalse(b.wantsMarkdownPreview)
    }

    func testWantsMarkdownPreviewTrue() {
        let b = SnippetBlock(language: "markdown", renderMarkdown: true)
        XCTAssertTrue(b.wantsMarkdownPreview)
    }

    func testWantsMarkdownPreviewNilRenderFlagIsFalse() {
        XCTAssertFalse(SnippetBlock(language: "markdown").wantsMarkdownPreview)
    }

    func testCodableRoundTripWithOverrides() throws {
        let b = SnippetBlock(
            title: "x",
            language: "markdown",
            content: "# hi",
            fontSize: 16,
            fontFamily: "Helvetica",
            renderMarkdown: true
        )
        let enc = JSONEncoder()
        let dec = JSONDecoder()
        let data = try enc.encode(b)
        let back = try dec.decode(SnippetBlock.self, from: data)
        XCTAssertEqual(back.fontSize, 16)
        XCTAssertEqual(back.fontFamily, "Helvetica")
        XCTAssertTrue(back.renderMarkdown)
    }

    func testDecodesLegacyJsonWithoutNewFields() throws {
        let legacyJson = """
        {
            "id": "\(UUID().uuidString)",
            "title": "legacy",
            "language": "rust",
            "content": "fn main() {}"
        }
        """.data(using: .utf8)!
        let b = try JSONDecoder().decode(SnippetBlock.self, from: legacyJson)
        XCTAssertEqual(b.title, "legacy")
        XCTAssertNil(b.fontSize)
        XCTAssertNil(b.fontFamily)
        XCTAssertFalse(b.renderMarkdown)
        XCTAssertEqual(b.effectiveFontSize, 13)
    }

    func testDecodesLegacyUseSerifFontIsIgnored() throws {
        // Old JSON had useSerifFont; we renamed it to fontFamily. The renamed
        // key is absent so the block should still decode cleanly.
        let legacyJson = """
        {
            "id": "\(UUID().uuidString)",
            "title": "with serif",
            "language": "plaintext",
            "content": "hi",
            "useSerifFont": true,
            "fontSize": 16
        }
        """.data(using: .utf8)!
        let b = try JSONDecoder().decode(SnippetBlock.self, from: legacyJson)
        XCTAssertEqual(b.fontSize, 16)
        XCTAssertNil(b.fontFamily)
    }

    func testNilOverridesFallBackToDefaults() {
        let b = SnippetBlock(fontSize: nil, fontFamily: nil, renderMarkdown: false)
        XCTAssertEqual(b.effectiveFontSize, 13)
        XCTAssertFalse(b.wantsMarkdownPreview)
    }
}
