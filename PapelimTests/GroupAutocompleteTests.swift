@testable import PapelimCore
import XCTest

final class GroupAutocompleteTests: XCTestCase {
    let candidates = ["work", "personal", "ansible", "ci", "scripts", "Work-archive"]

    func testEmptyQueryReturnsAllUpToLimit() {
        let out = GroupAutocomplete.suggestions(for: "", candidates: candidates, limit: 10)
        XCTAssertEqual(out, candidates)
    }

    func testEmptyQueryRespectsLimit() {
        let out = GroupAutocomplete.suggestions(for: "", candidates: candidates, limit: 3)
        XCTAssertEqual(out.count, 3)
        XCTAssertEqual(out, ["work", "personal", "ansible"])
    }

    func testSubstringMatchCaseInsensitive() {
        let out = GroupAutocomplete.suggestions(for: "work", candidates: candidates)
        // "work" itself is an exact match (excluded); "Work-archive" still matches.
        XCTAssertEqual(out, ["Work-archive"])
    }

    func testPartialMatch() {
        let out = GroupAutocomplete.suggestions(for: "scri", candidates: candidates)
        XCTAssertEqual(out, ["scripts"])
    }

    func testExactMatchExcluded() {
        let out = GroupAutocomplete.suggestions(for: "ci", candidates: candidates)
        XCTAssertFalse(out.contains("ci"))
    }

    func testExactMatchExcludedIsCaseInsensitive() {
        let out = GroupAutocomplete.suggestions(for: "WORK", candidates: candidates)
        XCTAssertFalse(out.contains("work"))
        XCTAssertTrue(out.contains("Work-archive"))
    }

    func testTrimsWhitespace() {
        let out = GroupAutocomplete.suggestions(for: "  scri  ", candidates: candidates)
        XCTAssertEqual(out, ["scripts"])
    }

    func testNoMatchesReturnsEmpty() {
        let out = GroupAutocomplete.suggestions(for: "zzz-nope", candidates: candidates)
        XCTAssertTrue(out.isEmpty)
    }

    func testPreservesCandidateOrder() {
        let out = GroupAutocomplete.suggestions(for: "", candidates: ["b", "a", "c"], limit: 10)
        XCTAssertEqual(out, ["b", "a", "c"])
    }

    func testEmptyCandidatesReturnsEmpty() {
        let out = GroupAutocomplete.suggestions(for: "anything", candidates: [])
        XCTAssertTrue(out.isEmpty)
    }
}
