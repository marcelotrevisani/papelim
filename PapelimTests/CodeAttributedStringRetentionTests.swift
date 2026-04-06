@testable import PapelimCore
import XCTest

// The crash occurred because `CodeEditor.Coordinator` held a `weak` reference
// to the `CodeAttributedString` (the NSTextStorage subclass). After
// `makeNSView` returned, nothing else retained it — so it was deallocated.
// Changing the language then accessed a dangling pointer.
//
// These tests exercise the same code paths at the model/core layer:
//   - switching a block's language between plain-text and code languages
//   - switching between two different code languages
//   - verifying the snippet round-trips correctly after the switch
//
// The actual AppKit retention fix is in the view layer (not testable here),
// but we ensure the model transitions that trigger the view swap are sound.

final class LanguageSwitchTests: XCTestCase {
    // MARK: - Model transitions that trigger the view swap

    func testSwitchFromPlaintextToCodeLanguage() {
        var block = SnippetBlock(language: "plaintext", content: "x = 1")
        XCTAssertTrue(block.wantsPlainTextEditor)

        block.language = "python"
        XCTAssertFalse(block.wantsPlainTextEditor)
        XCTAssertEqual(block.content, "x = 1", "content must survive language switch")
    }

    func testSwitchFromCodeToPlaintextLanguage() {
        var block = SnippetBlock(language: "rust", content: "fn main() {}")
        XCTAssertFalse(block.wantsPlainTextEditor)

        block.language = "plaintext"
        XCTAssertTrue(block.wantsPlainTextEditor)
        XCTAssertEqual(block.content, "fn main() {}")
    }

    func testSwitchBetweenTwoCodeLanguages() {
        var block = SnippetBlock(language: "bash", content: "echo hi")
        XCTAssertFalse(block.wantsPlainTextEditor)

        block.language = "python"
        XCTAssertFalse(block.wantsPlainTextEditor)
        XCTAssertEqual(Language.forId("python").hljs, "python")
        XCTAssertEqual(block.content, "echo hi")
    }

    func testSwitchFromMarkdownRenderedToCode() {
        var block = SnippetBlock(language: "markdown", content: "# Title", renderMarkdown: true)
        XCTAssertTrue(block.wantsMarkdownPreview)

        block.language = "python"
        XCTAssertFalse(block.wantsMarkdownPreview)
        XCTAssertFalse(block.wantsPlainTextEditor)
        XCTAssertEqual(block.content, "# Title")
    }

    func testSwitchFromCodeToMarkdown() {
        var block = SnippetBlock(language: "python", content: "# comment")
        block.language = "markdown"
        XCTAssertTrue(block.wantsPlainTextEditor)
        XCTAssertFalse(block.wantsMarkdownPreview) // render not toggled
        block.renderMarkdown = true
        XCTAssertTrue(block.wantsMarkdownPreview)
    }

    // MARK: - Round-trip through repository after language switch

    func testSaveAndLoadAfterLanguageSwitch() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("papelim-lang-switch-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        let loc = StorageLocation(name: "tmp", rawPath: tmp.path)
        let repo = SnippetRepository(locations: [loc])

        var snip = Snippet(
            title: "switch test",
            blocks: [SnippetBlock(language: "plaintext", content: "hello")]
        )

        // Save with plaintext
        try repo.save(snip)

        // Switch to python and re-save
        snip.blocks[0].language = "python"
        try repo.save(snip)

        let loaded = try repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].blocks[0].language, "python")
        XCTAssertEqual(loaded[0].blocks[0].content, "hello")
    }

    func testRapidLanguageSwitchesProduceValidState() {
        var block = SnippetBlock(language: "plaintext", content: "test")
        let languages = ["python", "rust", "bash", "yaml", "groovy",
                         "markdown", "plaintext", "cpp", "javascript"]

        for lang in languages {
            block.language = lang
            // Must never crash; content stays intact
            XCTAssertEqual(block.content, "test")
            // hljs lookup must resolve without crashing
            _ = Language.forId(lang).hljs
        }

        // After all switches, final state is correct
        XCTAssertEqual(block.language, "javascript")
    }

    func testAllLanguageIdsResolveToValidHljs() {
        // Every language in our list must produce a non-empty hljs grammar name,
        // so CodeAttributedString never gets a nil/empty language.
        for lang in Language.all {
            XCTAssertFalse(lang.hljs.isEmpty,
                           "\(lang.id) has empty hljs grammar — would crash Highlightr")
        }
    }
}
