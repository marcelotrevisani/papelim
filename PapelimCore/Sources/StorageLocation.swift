import Foundation

/// A folder the app reads from and writes snippets to. Users can configure
/// multiple locations (e.g. an iCloud Drive folder AND a Google Drive folder);
/// every write fans out to all enabled locations, every read merges them.
public struct StorageLocation: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var rawPath: String
    public var enabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        rawPath: String,
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.rawPath = rawPath
        self.enabled = enabled
    }

    public var url: URL { URL(fileURLWithPath: rawPath, isDirectory: true) }
}

public enum SuggestedLocations {
    /// Probe common sync-folder paths so first-run is zero-config.
    public static func detect(
        fileManager: FileManager = .default,
        home: URL? = nil
    ) -> [StorageLocation] {
        let home = home ?? fileManager.homeDirectoryForCurrentUser
        var found: [StorageLocation] = []

        let candidates: [(String, URL)] = [
            ("iCloud Drive", home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Papelim")),
            ("Google Drive", home.appendingPathComponent("Google Drive/Papelim")),
            ("Local",        home.appendingPathComponent("Documents/Papelim")),
        ]

        // Scan ~/Library/CloudStorage for Google Drive mounts
        let cloudStorage = home.appendingPathComponent("Library/CloudStorage")
        if let entries = try? fileManager.contentsOfDirectory(at: cloudStorage, includingPropertiesForKeys: nil) {
            for entry in entries where entry.lastPathComponent.hasPrefix("GoogleDrive") {
                let papelim = entry.appendingPathComponent("My Drive/Papelim")
                found.append(StorageLocation(name: "Google Drive", rawPath: papelim.path))
            }
        }

        for (name, url) in candidates {
            if fileManager.fileExists(atPath: url.deletingLastPathComponent().path) {
                found.append(StorageLocation(name: name, rawPath: url.path))
            }
        }

        var seen = Set<String>()
        return found.filter { seen.insert($0.rawPath).inserted }
    }
}
