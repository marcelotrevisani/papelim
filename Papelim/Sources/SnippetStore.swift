import Foundation
import PapelimCore
import SwiftUI

/// Sidebar selection: library root, a group, or a language filter.
enum SidebarSelection: Hashable {
    case all
    case group(String)
    case language(String)
}

/// UI-facing store. Wraps `SnippetRepository` with @Published state so SwiftUI
/// can observe changes. All persistence fans out to every enabled location.
@MainActor
final class SnippetStore: ObservableObject {
    @Published var snippets: [Snippet] = []
    @Published var selectedId: Snippet.ID?
    @Published var searchText: String = ""
    @Published var sidebarSelection: SidebarSelection? = .all
    @Published var locations: [StorageLocation] = []
    @Published var showingSettings: Bool = false
    @Published var lastSyncMessage: String = ""

    private let prefsKey = "papelim.locations.v1"
    private var repo: SnippetRepository
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init() {
        let loaded = Self.loadLocationsFromPrefs(key: prefsKey) ?? SuggestedLocations.detect()
        locations = loaded
        repo = SnippetRepository(locations: loaded)
        saveLocations()
    }

    // MARK: - Location persistence

    private static func loadLocationsFromPrefs(key: String) -> [StorageLocation]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try? d.decode([StorageLocation].self, from: data)
    }

    func saveLocations() {
        repo.setLocations(locations)
        guard let data = try? encoder.encode(locations) else { return }
        UserDefaults.standard.set(data, forKey: prefsKey)
    }

    func addLocation(_ loc: StorageLocation) {
        locations.append(loc)
        saveLocations()
        Task { await loadAll() }
    }

    func removeLocation(_ loc: StorageLocation) {
        locations.removeAll { $0.id == loc.id }
        saveLocations()
    }

    func toggleLocation(_ loc: StorageLocation) {
        guard let idx = locations.firstIndex(where: { $0.id == loc.id }) else { return }
        locations[idx].enabled.toggle()
        saveLocations()
        Task { await loadAll() }
    }

    // MARK: - CRUD

    func loadAll() async {
        do {
            let loaded = try repo.loadAll()
            snippets = loaded
            if selectedId == nil {
                selectedId = loaded.first?.id
            }
            let n = repo.activeLocations.count
            lastSyncMessage = "Loaded \(loaded.count) snippet\(loaded.count == 1 ? "" : "s") from \(n) location\(n == 1 ? "" : "s")"
        } catch {
            lastSyncMessage = "Load failed: \(error.localizedDescription)"
        }
    }

    func createNew() {
        let snip = Snippet(title: "New Snippet")
        snippets.insert(snip, at: 0)
        selectedId = snip.id
        persist(snip)
    }

    func update(_ snippet: Snippet) {
        var copy = snippet
        copy.updatedAt = Date()
        if let idx = snippets.firstIndex(where: { $0.id == copy.id }) {
            snippets[idx] = copy
        } else {
            snippets.insert(copy, at: 0)
        }
        persist(copy)
    }

    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        if selectedId == snippet.id {
            selectedId = snippets.first?.id
        }
        _ = repo.delete(snippet)
    }

    private func persist(_ snippet: Snippet) {
        do {
            let failures = try repo.save(snippet)
            if failures.isEmpty {
                lastSyncMessage = "Saved to \(repo.activeLocations.count) location(s)"
            } else {
                lastSyncMessage = "Write failed → " + failures.map { "\($0.0.name): \($0.1.localizedDescription)" }.joined(separator: " · ")
            }
        } catch {
            lastSyncMessage = "Encode failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Derived filtering

    var filtered: [Snippet] {
        var languageFilter: String? = nil
        var groupFilter: String? = nil
        switch sidebarSelection ?? .all {
        case .all: break
        case let .group(g): groupFilter = g
        case let .language(l): languageFilter = l
        }
        return SnippetFiltering.filter(
            snippets,
            searchText: searchText,
            languageFilter: languageFilter,
            groupFilter: groupFilter
        ).sorted { $0.updatedAt > $1.updatedAt }
    }

    var listTitle: String {
        switch sidebarSelection ?? .all {
        case .all: return "All Snippets"
        case let .group(g): return g
        case let .language(l): return Language.forId(l).display
        }
    }

    func binding(for id: Snippet.ID) -> Binding<Snippet>? {
        guard let idx = snippets.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.snippets[idx] },
            set: { self.update($0) }
        )
    }
}
