import Foundation

/// Parsed markdown broken into rendering-friendly block-level pieces.
/// Intentionally pragmatic — not a conformant CommonMark parser, just what's
/// needed to render snippets nicely.
public enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case unorderedList([String])
    case orderedList([String])
    case blockquote(String)
    case codeBlock(language: String?, code: String)
    case rule
    case empty
}

public enum MarkdownParser {
    public static func parse(_ source: String) -> [MarkdownBlock] {
        let lines = source.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var i = 0

        while i < lines.count {
            let raw = lines[i]
            let line = raw.trimmingCharacters(in: .whitespaces)

            // Blank line → block separator
            if line.isEmpty {
                i += 1
                continue
            }

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count {
                    let l = lines[i]
                    if l.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        i += 1
                        break
                    }
                    code.append(l)
                    i += 1
                }
                blocks.append(.codeBlock(
                    language: lang.isEmpty ? nil : lang,
                    code: code.joined(separator: "\n")
                ))
                continue
            }

            // Horizontal rule
            if line == "---" || line == "***" || line == "___" {
                blocks.append(.rule)
                i += 1
                continue
            }

            // Heading
            if let heading = parseHeading(line) {
                blocks.append(heading)
                i += 1
                continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                var quoted: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix(">") {
                        quoted.append(String(l.dropFirst()).trimmingCharacters(in: .whitespaces))
                        i += 1
                    } else {
                        break
                    }
                }
                blocks.append(.blockquote(quoted.joined(separator: " ")))
                continue
            }

            // Unordered list
            if isUnorderedListMarker(line) {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if isUnorderedListMarker(l) {
                        items.append(stripListMarker(l, ordered: false))
                        i += 1
                    } else {
                        break
                    }
                }
                blocks.append(.unorderedList(items))
                continue
            }

            // Ordered list
            if isOrderedListMarker(line) {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if isOrderedListMarker(l) {
                        items.append(stripListMarker(l, ordered: true))
                        i += 1
                    } else {
                        break
                    }
                }
                blocks.append(.orderedList(items))
                continue
            }

            // Paragraph: consume until blank or block-level marker
            var para: [String] = [line]
            i += 1
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if l.isEmpty {
                    break
                }
                if l.hasPrefix("#") {
                    break
                }
                if l.hasPrefix(">") {
                    break
                }
                if l.hasPrefix("```") {
                    break
                }
                if isUnorderedListMarker(l) || isOrderedListMarker(l) {
                    break
                }
                if l == "---" || l == "***" || l == "___" {
                    break
                }
                para.append(l)
                i += 1
            }
            blocks.append(.paragraph(para.joined(separator: " ")))
        }

        return blocks
    }

    // MARK: - helpers

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for ch in line {
            if ch == "#" {
                level += 1
            } else {
                break
            }
        }
        guard (1 ... 6).contains(level) else { return nil }
        let rest = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }
        return .heading(level: level, text: rest)
    }

    private static func isUnorderedListMarker(_ s: String) -> Bool {
        guard s.count >= 2 else { return false }
        let first = s.first!
        let second = s[s.index(after: s.startIndex)]
        return (first == "-" || first == "*" || first == "+") && second == " "
    }

    private static func isOrderedListMarker(_ s: String) -> Bool {
        // e.g. "1. item" or "12) item"
        var digits = 0
        for ch in s {
            if ch.isNumber {
                digits += 1
            } else {
                break
            }
        }
        guard digits > 0, s.count > digits + 1 else { return false }
        let idx = s.index(s.startIndex, offsetBy: digits)
        let marker = s[idx]
        guard marker == "." || marker == ")" else { return false }
        let next = s.index(after: idx)
        return next < s.endIndex && s[next] == " "
    }

    private static func stripListMarker(_ s: String, ordered: Bool) -> String {
        if ordered {
            // drop digits then "." or ")" then space
            var idx = s.startIndex
            while idx < s.endIndex, s[idx].isNumber {
                idx = s.index(after: idx)
            }
            if idx < s.endIndex, s[idx] == "." || s[idx] == ")" {
                idx = s.index(after: idx)
            }
            while idx < s.endIndex, s[idx] == " " {
                idx = s.index(after: idx)
            }
            return String(s[idx...])
        } else {
            return String(s.dropFirst(2))
        }
    }
}
