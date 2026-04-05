import SwiftUI
import AppKit
import Highlightr
import PapelimCore

/// NSTextView-backed SwiftUI editor. Uses Highlightr's `CodeAttributedString`
/// (an `NSTextStorage` subclass) so that highlighting happens automatically as
/// the user types — we don't have to replace the text on every keystroke.
struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    var languageId: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = CodeAttributedString()
        textStorage.highlightr.setTheme(to: "atom-one-dark")
        textStorage.language = Language.forId(languageId).hljs

        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let textContainer = NSTextContainer(containerSize: containerSize)
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .white
        textView.insertionPointColor = .white
        textView.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.20, alpha: 1.0)
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true

        // Seed initial text
        textStorage.setAttributedString(NSAttributedString(string: text))

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false

        context.coordinator.textView = textView
        context.coordinator.textStorage = textStorage
        context.coordinator.lastLanguage = Language.forId(languageId).hljs
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let tv = context.coordinator.textView,
              let storage = context.coordinator.textStorage else { return }

        // Language change → retint the whole document.
        let newLang = Language.forId(languageId).hljs
        if newLang != context.coordinator.lastLanguage {
            storage.language = newLang
            context.coordinator.lastLanguage = newLang
        }

        // External text change (e.g. switching to a different snippet) → replace.
        // We do NOT touch the storage on every keystroke — only when the binding
        // value really differs from what the user is already looking at.
        if tv.string != text {
            context.coordinator.applying = true
            let selected = tv.selectedRange()
            storage.replaceCharacters(in: NSRange(location: 0, length: storage.length),
                                      with: text)
            let clampedLoc = min(selected.location, storage.length)
            tv.setSelectedRange(NSRange(location: clampedLoc, length: 0))
            context.coordinator.applying = false
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditor
        weak var textView: NSTextView?
        weak var textStorage: CodeAttributedString?
        var lastLanguage: String = ""
        var applying = false

        init(_ parent: CodeEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !applying, let tv = textView else { return }
            // Propagate plain text back up; highlighting is handled by
            // CodeAttributedString automatically.
            parent.text = tv.string
        }
    }
}
