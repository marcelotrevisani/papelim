@testable import PapelimCore
import XCTest

final class LanguageTests: XCTestCase {
    func testAllLanguagesHaveUniqueIds() {
        let ids = Language.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Language ids must be unique")
    }

    func testForIdReturnsCorrectLanguage() {
        XCTAssertEqual(Language.forId("rust").display, "Rust")
        XCTAssertEqual(Language.forId("github-actions").hljs, "yaml")
        XCTAssertEqual(Language.forId("justfile").hljs, "makefile")
        XCTAssertEqual(Language.forId("nushell").hljs, "bash")
    }

    func testForIdUnknownFallsBackToPlaintext() {
        let l = Language.forId("this-does-not-exist")
        XCTAssertEqual(l.id, "plaintext")
    }

    func testRequiredLanguagesPresent() {
        let required = ["groovy", "github-actions", "yaml", "plaintext",
                        "python", "rust", "c", "cpp", "javascript",
                        "bash", "nushell", "justfile"]
        let ids = Set(Language.all.map(\.id))
        for r in required {
            XCTAssertTrue(ids.contains(r), "missing required language: \(r)")
        }
    }
}
