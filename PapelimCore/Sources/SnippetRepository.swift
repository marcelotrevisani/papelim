import Foundation

/// Pure file-I/O layer. No UI dependencies — this is what the tests exercise.
///
/// Reads: merge all enabled locations by `id`, newest `updatedAt` wins.
/// Writes/Deletes: fan out to every enabled location.
public final class SnippetRepository {
    public private(set) var locations: [StorageLocation]
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(locations: [StorageLocation], fileManager: FileManager = .default) {
        self.locations = locations
        self.fileManager = fileManager

        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        encoder = e

        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        decoder = d
    }

    public func setLocations(_ locations: [StorageLocation]) {
        self.locations = locations
    }

    /// All enabled, writable locations.
    public var activeLocations: [StorageLocation] {
        locations.filter { $0.enabled }
    }

    @discardableResult
    public func ensureDirectories() -> [Error] {
        var errors: [Error] = []
        for loc in activeLocations {
            do {
                try fileManager.createDirectory(at: loc.url, withIntermediateDirectories: true)
            } catch {
                errors.append(error)
            }
        }
        return errors
    }

    /// Merge all snippets across enabled locations. Newest `updatedAt` wins per id.
    public func loadAll() throws -> [Snippet] {
        var merged: [UUID: Snippet] = [:]
        for loc in activeLocations {
            try? fileManager.createDirectory(at: loc.url, withIntermediateDirectories: true)
            guard fileManager.fileExists(atPath: loc.rawPath) else { continue }
            let entries = (try? fileManager.contentsOfDirectory(
                at: loc.url, includingPropertiesForKeys: nil
            )) ?? []
            for file in entries where file.pathExtension == "json" {
                guard let data = try? Data(contentsOf: file),
                      let snip = try? decoder.decode(Snippet.self, from: data)
                else { continue }
                if let existing = merged[snip.id] {
                    if snip.updatedAt > existing.updatedAt {
                        merged[snip.id] = snip
                    }
                } else {
                    merged[snip.id] = snip
                }
            }
        }
        return merged.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Write a snippet to every enabled location.
    /// Returns the list of locations where writing failed.
    @discardableResult
    public func save(_ snippet: Snippet) throws -> [(StorageLocation, Error)] {
        let data = try encoder.encode(snippet)
        var failures: [(StorageLocation, Error)] = []
        for loc in activeLocations {
            do {
                try fileManager.createDirectory(at: loc.url, withIntermediateDirectories: true)
                let url = loc.url.appendingPathComponent(snippet.fileName)
                try data.write(to: url, options: .atomic)
            } catch {
                failures.append((loc, error))
            }
        }
        return failures
    }

    /// Delete a snippet from every enabled location.
    @discardableResult
    public func delete(_ snippet: Snippet) -> [(StorageLocation, Error)] {
        var failures: [(StorageLocation, Error)] = []
        for loc in activeLocations {
            let url = loc.url.appendingPathComponent(snippet.fileName)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            do {
                try fileManager.removeItem(at: url)
            } catch {
                failures.append((loc, error))
            }
        }
        return failures
    }
}
