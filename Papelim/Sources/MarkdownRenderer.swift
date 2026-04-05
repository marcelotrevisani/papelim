import PapelimCore
import SwiftUI

/// Renders the output of `MarkdownParser.parse` as SwiftUI views.
/// Inline emphasis (`*x*`, `**x**`, `` `x` ``) is handled via
/// AttributedString(markdown:) per-paragraph.
struct MarkdownRenderer: View {
    let source: String
    let baseFontSize: Double

    private var blocks: [MarkdownBlock] { MarkdownParser.parse(source) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                view(for: block)
            }
        }
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inline(text))
                .font(.system(size: headingSize(level), weight: .bold))
                .padding(.top, level == 1 ? 4 : 2)
        case let .paragraph(text):
            Text(inline(text))
                .font(.system(size: baseFontSize))
                .fixedSize(horizontal: false, vertical: true)
        case let .unorderedList(items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").font(.system(size: baseFontSize))
                        Text(inline(item)).font(.system(size: baseFontSize))
                    }
                }
            }
        case let .orderedList(items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(idx + 1).").font(.system(size: baseFontSize)).monospacedDigit()
                        Text(inline(item)).font(.system(size: baseFontSize))
                    }
                }
            }
        case let .blockquote(text):
            HStack(spacing: 8) {
                Rectangle().fill(Color.secondary.opacity(0.4)).frame(width: 3)
                Text(inline(text))
                    .font(.system(size: baseFontSize).italic())
                    .foregroundStyle(.secondary)
            }
        case let .codeBlock(_, code):
            Text(code)
                .font(.system(size: baseFontSize - 1, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        case .rule:
            Divider()
        case .empty:
            EmptyView()
        }
    }

    private func headingSize(_ level: Int) -> Double {
        switch level {
        case 1: return baseFontSize + 10
        case 2: return baseFontSize + 7
        case 3: return baseFontSize + 4
        case 4: return baseFontSize + 2
        default: return baseFontSize + 1
        }
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }
}
