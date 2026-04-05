import Foundation

public enum SnippetFiltering {
    /// Filter snippets by free-text search, language, and group.
    /// Search matches title, tags, block titles, and block contents.
    public static func filter(
        _ snippets: [Snippet],
        searchText: String = "",
        languageFilter: String? = nil,
        groupFilter: String? = nil
    ) -> [Snippet] {
        snippets.filter { snip in
            let languageMatch = languageFilter == nil || snip.usesLanguage(languageFilter!)
            let groupMatch: Bool = {
                guard let groupFilter else { return true }
                return snip.group == groupFilter
            }()
            let searchMatch: Bool = {
                guard !searchText.isEmpty else { return true }
                if snip.title.localizedCaseInsensitiveContains(searchText) { return true }
                if snip.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) { return true }
                if let group = snip.group, group.localizedCaseInsensitiveContains(searchText) { return true }
                for block in snip.blocks {
                    if block.title.localizedCaseInsensitiveContains(searchText) { return true }
                    if block.content.localizedCaseInsensitiveContains(searchText) { return true }
                }
                return false
            }()
            return languageMatch && groupMatch && searchMatch
        }
    }

    /// Distinct group names present in a snippet collection, sorted alphabetically.
    public static func groups(in snippets: [Snippet]) -> [String] {
        let names = snippets.compactMap(\.group).filter { !$0.isEmpty }
        return Array(Set(names)).sorted()
    }
}
