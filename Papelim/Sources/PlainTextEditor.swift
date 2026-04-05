import SwiftUI
import AppKit

/// Plain (non-highlighted) text editor with configurable font. Used for
/// `plaintext` and (edit-mode) `markdown` block types.
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double
    var fontFamily: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        guard let tv = scroll.documentView as? NSTextView else { return scroll }
        tv.delegate = context.coordinator
        tv.isEditable = true
        tv.isSelectable = true
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.font = Self.font(size: fontSize, family: fontFamily)
        tv.textContainerInset = NSSize(width: 8, height: 8)
        tv.drawsBackground = true
        tv.backgroundColor = NSColor.textBackgroundColor
        tv.textColor = NSColor.labelColor
        tv.string = text
        context.coordinator.textView = tv
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let tv = context.coordinator.textView else { return }
        let desired = Self.font(size: fontSize, family: fontFamily)
        if tv.font != desired { tv.font = desired }
        if tv.string != text {
            context.coordinator.applying = true
            let sel = tv.selectedRange()
            tv.string = text
            tv.setSelectedRange(NSRange(location: min(sel.location, (text as NSString).length),
                                        length: 0))
            context.coordinator.applying = false
        }
    }

    private static func font(size: Double, family: String?) -> NSFont {
        let sz = CGFloat(size)
        if let family,
           let font = NSFontManager.shared.font(
                withFamily: family, traits: [], weight: 5, size: sz) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: sz, weight: .regular)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        weak var textView: NSTextView?
        var applying = false
        init(_ parent: PlainTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard !applying, let tv = textView else { return }
            parent.text = tv.string
        }
    }
}
