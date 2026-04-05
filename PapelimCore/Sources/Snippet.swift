import Foundation

/// A single code block inside a snippet. A snippet can have many blocks,
/// each with its own language — useful for mixing e.g. a shell command and
/// the YAML it produces in one logical snippet.
public struct SnippetBlock: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var language: String
    public var content: String

    /// Only meaningful for plaintext / markdown blocks. nil → default (13).
    public var fontSize: Double?
    /// Font family name from the system font list. nil → default monospace.
    public var fontFamily: String?
    /// false → show editor, true → show rendered markdown preview.
    public var renderMarkdown: Bool

    public init(
        id: UUID = UUID(),
        title: String = "",
        language: String = "plaintext",
        content: String = "",
        fontSize: Double? = nil,
        fontFamily: String? = nil,
        renderMarkdown: Bool = false
    ) {
        self.id = id
        self.title = title
        self.language = language
        self.content = content
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.renderMarkdown = renderMarkdown
    }

    public var effectiveFontSize: Double { fontSize ?? 13 }
    public var wantsMarkdownPreview: Bool { renderMarkdown && language == "markdown" }
    public var wantsPlainTextEditor: Bool { language == "plaintext" || language == "markdown" }

    // Custom decoder: `renderMarkdown` is a new non-optional field, so legacy
    // JSON (pre-existing snippets) won't have the key. Decode it as false.
    private enum CodingKeys: String, CodingKey {
        case id, title, language, content, fontSize, fontFamily, renderMarkdown
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.language = try c.decodeIfPresent(String.self, forKey: .language) ?? "plaintext"
        self.content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        self.fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize)
        self.fontFamily = try c.decodeIfPresent(String.self, forKey: .fontFamily)
        self.renderMarkdown = try c.decodeIfPresent(Bool.self, forKey: .renderMarkdown) ?? false
    }
}

public struct Snippet: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var group: String?
    public var tags: [String]
    public var blocks: [SnippetBlock]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        group: String? = nil,
        tags: [String] = [],
        blocks: [SnippetBlock] = [SnippetBlock()],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.group = group
        self.tags = tags
        self.blocks = blocks.isEmpty ? [SnippetBlock()] : blocks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var fileName: String { "\(id.uuidString).json" }

    /// The first block's language — used for rollup display/filtering.
    public var primaryLanguage: String { blocks.first?.language ?? "plaintext" }

    /// Does any block in this snippet use the given language id?
    public func usesLanguage(_ languageId: String) -> Bool {
        blocks.contains { $0.language == languageId }
    }
}
