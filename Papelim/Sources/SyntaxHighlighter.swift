import AppKit
import Highlightr
import PapelimCore

/// Thin wrapper around Highlightr that produces NSAttributedString for a
/// given language id. Falls back to plaintext on unknown grammars.
final class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()

    private let hl: Highlightr

    private init() {
        let h = Highlightr()!
        h.setTheme(to: "atom-one-dark")
        hl = h
    }

    func highlight(_ code: String, languageId: String) -> NSAttributedString {
        let lang = Language.forId(languageId).hljs
        if let attr = hl.highlight(code, as: lang, fastRender: true) {
            return attr
        }
        return NSAttributedString(
            string: code,
            attributes: [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]
        )
    }
}
