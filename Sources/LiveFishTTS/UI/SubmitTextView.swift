import AppKit
import SwiftUI

struct SubmitTextView: NSViewRepresentable {
    struct PendingInsertion: Equatable, Identifiable {
        let id: UUID
        let text: String

        init(text: String) {
            self.id = UUID()
            self.text = text
        }
    }

    @Binding var text: String
    var placeholder: String
    var checkSpelling: Bool
    var autoCorrectSpelling: Bool
    var checkGrammar: Bool
    @Binding var pendingInsertion: PendingInsertion?
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 24)
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.string = text
        textView.allowsUndo = true
        textView.drawsBackground = false
        applyTypingAssistance(to: textView)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            textView.window?.makeKeyAndOrderFront(nil)
            textView.window?.makeFirstResponder(textView)
        }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        if let insertion = pendingInsertion,
           context.coordinator.lastAppliedInsertionID != insertion.id {
            context.coordinator.lastAppliedInsertionID = insertion.id
            insert(insertion.text, into: textView)
            DispatchQueue.main.async {
                if pendingInsertion?.id == insertion.id {
                    pendingInsertion = nil
                }
            }
        }
        applyTypingAssistance(to: textView)
        DispatchQueue.main.async {
            if textView.window?.isKeyWindow == true {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    private func insert(_ insertion: String, into textView: NSTextView) {
        let selectedRange = textView.selectedRange()
        textView.insertText(insertion, replacementRange: selectedRange)
        text = textView.string
    }

    private func applyTypingAssistance(to textView: NSTextView) {
        textView.isContinuousSpellCheckingEnabled = checkSpelling
        textView.isGrammarCheckingEnabled = checkGrammar
        textView.isAutomaticSpellingCorrectionEnabled = autoCorrectSpelling
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SubmitTextView
        var lastAppliedInsertionID: UUID?

        init(_ parent: SubmitTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else {
                return false
            }
            if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
                textView.insertNewlineIgnoringFieldEditor(nil)
                parent.text = textView.string
                return true
            }
            parent.text = textView.string
            parent.onSubmit()
            return true
        }
    }
}
