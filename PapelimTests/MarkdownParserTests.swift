import XCTest
@testable import PapelimCore

final class MarkdownParserTests: XCTestCase {

    func testEmptyInputProducesNoBlocks() {
        XCTAssertTrue(MarkdownParser.parse("").isEmpty)
    }

    func testBlankLinesOnlyProducesNoBlocks() {
        XCTAssertTrue(MarkdownParser.parse("\n\n\n").isEmpty)
    }

    func testParagraphOneLine() {
        let out = MarkdownParser.parse("Hello world.")
        XCTAssertEqual(out, [.paragraph("Hello world.")])
    }

    func testMultiLineParagraphJoinsWithSpace() {
        let out = MarkdownParser.parse("line one\nline two\nline three")
        XCTAssertEqual(out, [.paragraph("line one line two line three")])
    }

    func testBlankLineSeparatesParagraphs() {
        let out = MarkdownParser.parse("first\n\nsecond")
        XCTAssertEqual(out, [.paragraph("first"), .paragraph("second")])
    }

    func testHeadingsAllLevels() {
        let src = """
        # h1
        ## h2
        ### h3
        #### h4
        ##### h5
        ###### h6
        """
        let out = MarkdownParser.parse(src)
        XCTAssertEqual(out, [
            .heading(level: 1, text: "h1"),
            .heading(level: 2, text: "h2"),
            .heading(level: 3, text: "h3"),
            .heading(level: 4, text: "h4"),
            .heading(level: 5, text: "h5"),
            .heading(level: 6, text: "h6"),
        ])
    }

    func testSevenHashesIsNotHeading() {
        let out = MarkdownParser.parse("####### too many")
        // 7 hashes with content → not a heading → paragraph
        if case .paragraph = out.first { } else {
            XCTFail("expected paragraph, got \(String(describing: out.first))")
        }
    }

    func testEmptyHeadingIsNotHeading() {
        let out = MarkdownParser.parse("## ")
        // no content after hashes → treated as paragraph
        XCTAssertEqual(out, [.paragraph("##")])
    }

    func testUnorderedListDash() {
        let out = MarkdownParser.parse("- one\n- two\n- three")
        XCTAssertEqual(out, [.unorderedList(["one", "two", "three"])])
    }

    func testUnorderedListStar() {
        let out = MarkdownParser.parse("* a\n* b")
        XCTAssertEqual(out, [.unorderedList(["a", "b"])])
    }

    func testUnorderedListPlus() {
        let out = MarkdownParser.parse("+ a\n+ b")
        XCTAssertEqual(out, [.unorderedList(["a", "b"])])
    }

    func testOrderedListWithDot() {
        let out = MarkdownParser.parse("1. first\n2. second\n3. third")
        XCTAssertEqual(out, [.orderedList(["first", "second", "third"])])
    }

    func testOrderedListWithParenthesis() {
        let out = MarkdownParser.parse("1) a\n2) b")
        XCTAssertEqual(out, [.orderedList(["a", "b"])])
    }

    func testOrderedListMultiDigit() {
        let out = MarkdownParser.parse("10. ten\n11. eleven")
        XCTAssertEqual(out, [.orderedList(["ten", "eleven"])])
    }

    func testBlockquoteSingleLine() {
        let out = MarkdownParser.parse("> be great")
        XCTAssertEqual(out, [.blockquote("be great")])
    }

    func testBlockquoteMultiLine() {
        let out = MarkdownParser.parse("> line one\n> line two")
        XCTAssertEqual(out, [.blockquote("line one line two")])
    }

    func testFencedCodeBlockWithLanguage() {
        let src = "```swift\nlet x = 1\nlet y = 2\n```"
        let out = MarkdownParser.parse(src)
        XCTAssertEqual(out, [.codeBlock(language: "swift", code: "let x = 1\nlet y = 2")])
    }

    func testFencedCodeBlockNoLanguage() {
        let src = "```\nsome code\n```"
        let out = MarkdownParser.parse(src)
        XCTAssertEqual(out, [.codeBlock(language: nil, code: "some code")])
    }

    func testFencedCodeBlockPreservesBlankLines() {
        let src = "```\nline1\n\nline3\n```"
        let out = MarkdownParser.parse(src)
        XCTAssertEqual(out, [.codeBlock(language: nil, code: "line1\n\nline3")])
    }

    func testHorizontalRules() {
        XCTAssertEqual(MarkdownParser.parse("---"), [.rule])
        XCTAssertEqual(MarkdownParser.parse("***"), [.rule])
        XCTAssertEqual(MarkdownParser.parse("___"), [.rule])
    }

    func testMixedDocument() {
        let src = """
        # Title

        An intro paragraph.

        ## List

        - alpha
        - beta

        > quoted wisdom

        ```bash
        echo hi
        ```

        ---

        1. first
        2. second
        """
        let out = MarkdownParser.parse(src)
        XCTAssertEqual(out, [
            .heading(level: 1, text: "Title"),
            .paragraph("An intro paragraph."),
            .heading(level: 2, text: "List"),
            .unorderedList(["alpha", "beta"]),
            .blockquote("quoted wisdom"),
            .codeBlock(language: "bash", code: "echo hi"),
            .rule,
            .orderedList(["first", "second"]),
        ])
    }

    func testParagraphStopsAtHeading() {
        let out = MarkdownParser.parse("para line\n# heading")
        XCTAssertEqual(out, [.paragraph("para line"), .heading(level: 1, text: "heading")])
    }

    func testParagraphStopsAtList() {
        let out = MarkdownParser.parse("some para\n- item")
        XCTAssertEqual(out, [.paragraph("some para"), .unorderedList(["item"])])
    }

    func testParagraphStopsAtBlockquote() {
        let out = MarkdownParser.parse("some para\n> quote")
        XCTAssertEqual(out, [.paragraph("some para"), .blockquote("quote")])
    }

    func testParagraphStopsAtCodeFence() {
        let out = MarkdownParser.parse("some para\n```\ncode\n```")
        XCTAssertEqual(out, [.paragraph("some para"), .codeBlock(language: nil, code: "code")])
    }

    func testAdjacentListAndParagraphNotMerged() {
        let out = MarkdownParser.parse("- a\n- b\ntext after")
        XCTAssertEqual(out, [.unorderedList(["a", "b"]), .paragraph("text after")])
    }

    func testTextResemblingListMarkerButNoSpace() {
        // "-foo" is not a list item (no space after marker)
        let out = MarkdownParser.parse("-foo")
        XCTAssertEqual(out, [.paragraph("-foo")])
    }

    func testNumberWithoutListMarkerIsParagraph() {
        let out = MarkdownParser.parse("1 is a number")
        XCTAssertEqual(out, [.paragraph("1 is a number")])
    }

    func testUnclosedFenceConsumesToEnd() {
        let out = MarkdownParser.parse("```\nno close\nmore")
        XCTAssertEqual(out, [.codeBlock(language: nil, code: "no close\nmore")])
    }
}
