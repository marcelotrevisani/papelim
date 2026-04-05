import Foundation

/// Languages exposed in the UI. `hljs` is the grammar id consumed by
/// Highlightr / highlight.js. Niche languages (nushell, justfile) fall back
/// to their closest cousin since highlight.js has no native grammar.
public struct Language: Identifiable, Hashable, Sendable {
    public let id: String
    public let display: String
    public let hljs: String

    public init(id: String, display: String, hljs: String) {
        self.id = id
        self.display = display
        self.hljs = hljs
    }

    public static let all: [Language] = [
        Language(id: "plaintext",      display: "Plain Text",     hljs: "plaintext"),
        Language(id: "bash",           display: "Bash",           hljs: "bash"),
        Language(id: "nushell",        display: "Nushell",        hljs: "bash"),
        Language(id: "justfile",       display: "Justfile",       hljs: "makefile"),
        Language(id: "python",         display: "Python",         hljs: "python"),
        Language(id: "rust",           display: "Rust",           hljs: "rust"),
        Language(id: "c",              display: "C",              hljs: "c"),
        Language(id: "cpp",            display: "C++",            hljs: "cpp"),
        Language(id: "javascript",     display: "JavaScript",     hljs: "javascript"),
        Language(id: "typescript",     display: "TypeScript",     hljs: "typescript"),
        Language(id: "groovy",         display: "Groovy",         hljs: "groovy"),
        Language(id: "yaml",           display: "YAML",           hljs: "yaml"),
        Language(id: "github-actions", display: "GitHub Actions", hljs: "yaml"),
        Language(id: "json",           display: "JSON",           hljs: "json"),
        Language(id: "toml",           display: "TOML",           hljs: "ini"),
        Language(id: "markdown",       display: "Markdown",       hljs: "markdown"),
        Language(id: "sql",            display: "SQL",            hljs: "sql"),
        Language(id: "go",             display: "Go",             hljs: "go"),
        Language(id: "swift",          display: "Swift",          hljs: "swift"),
        Language(id: "ruby",           display: "Ruby",           hljs: "ruby"),
        Language(id: "dockerfile",     display: "Dockerfile",     hljs: "dockerfile"),
    ]

    public static func forId(_ id: String) -> Language {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
