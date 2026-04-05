import Foundation

public enum GroupAutocomplete {
    /// Returns group names matching `query` (case-insensitive substring).
    /// - Excludes an exact case-insensitive match of the query itself (no point
    ///   suggesting what the user already typed).
    /// - Empty query returns all candidates, limited by `limit`.
    /// - Results preserve the input order of `candidates`.
    public static func suggestions(
        for query: String,
        candidates: [String],
        limit: Int = 8
    ) -> [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let filtered = candidates.filter { cand in
            guard cand.caseInsensitiveCompare(q) != .orderedSame else { return false }
            return q.isEmpty || cand.localizedCaseInsensitiveContains(q)
        }
        return Array(filtered.prefix(limit))
    }
}
