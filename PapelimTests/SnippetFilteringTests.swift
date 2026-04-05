@testable import PapelimCore
import XCTest

final class SnippetFilteringTests: XCTestCase {
    let snippets: [Snippet] = [
        Snippet(title: "Python hello",
                group: "scripts",
                tags: ["cli"],
                blocks: [SnippetBlock(language: "python", content: "print('hi')")]),
        Snippet(title: "Bash loop",
                group: "scripts",
                tags: [],
                blocks: [SnippetBlock(language: "bash", content: "for i in 1 2 3; do echo $i; done")]),
        Snippet(title: "GHA workflow",
                group: "ci",
                tags: ["automation"],
                blocks: [SnippetBlock(language: "github-actions", content: "on: push")]),
        Snippet(title: "Rust + cargo",
                group: nil,
                tags: [],
                blocks: [
                    SnippetBlock(title: "src/main.rs", language: "rust", content: "fn main() {}"),
                    SnippetBlock(title: "build", language: "bash", content: "cargo build"),
                ]),
    ]

    func testEmptyArgsReturnsAll() {
        XCTAssertEqual(SnippetFiltering.filter(snippets).count, 4)
    }

    func testLanguageFilterMatchesAnyBlock() {
        // bash appears as primary in "Bash loop" AND as secondary block in "Rust + cargo"
        let out = SnippetFiltering.filter(snippets, languageFilter: "bash")
        XCTAssertEqual(out.count, 2)
    }

    func testGroupFilter() {
        let out = SnippetFiltering.filter(snippets, groupFilter: "scripts")
        XCTAssertEqual(out.count, 2)
        XCTAssertTrue(out.allSatisfy { $0.group == "scripts" })
    }

    func testSearchMatchesTitle() {
        let out = SnippetFiltering.filter(snippets, searchText: "PYTHON")
        XCTAssertEqual(out.count, 1)
    }

    func testSearchMatchesBlockContent() {
        let out = SnippetFiltering.filter(snippets, searchText: "cargo build")
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].title, "Rust + cargo")
    }

    func testSearchMatchesBlockTitle() {
        let out = SnippetFiltering.filter(snippets, searchText: "main.rs")
        XCTAssertEqual(out.count, 1)
    }

    func testSearchMatchesTag() {
        let out = SnippetFiltering.filter(snippets, searchText: "automation")
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].title, "GHA workflow")
    }

    func testSearchMatchesGroup() {
        let out = SnippetFiltering.filter(snippets, searchText: "ci")
        // "ci" hits group="ci" AND tag="cli" (substring)
        XCTAssertTrue(out.count >= 1)
        XCTAssertTrue(out.contains { $0.title == "GHA workflow" })
    }

    func testCombinedFilters() {
        let out = SnippetFiltering.filter(snippets,
                                          searchText: "loop",
                                          languageFilter: "bash",
                                          groupFilter: "scripts")
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].title, "Bash loop")
    }

    func testGroupsEnumeration() {
        let groups = SnippetFiltering.groups(in: snippets)
        XCTAssertEqual(groups, ["ci", "scripts"])
    }
}
