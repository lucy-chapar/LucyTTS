import SwiftUI
import UIKit

struct iOSSubmitTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var pendingInsertion: String?
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .title3)
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.textColor = UIColor(
            red: 0.13,
            green: 0.05,
            blue: 0.16,
            alpha: 1.0
        )
        textView.tintColor = UIColor(
            red: 0.95,
            green: 0.26,
            blue: 0.58,
            alpha: 1.0
        )
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.text = text

        DispatchQueue.main.async {
            textView.becomeFirstResponder()
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
        if let insertion = pendingInsertion {
            insert(insertion, into: textView)
            DispatchQueue.main.async {
                pendingInsertion = nil
            }
        }

        DispatchQueue.main.async {
            if textView.window != nil, !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        }
    }

    private func insert(_ insertion: String, into textView: UITextView) {
        if let selectedRange = textView.selectedTextRange {
            textView.replace(selectedRange, withText: insertion)
        } else {
            textView.text.append(insertion)
            textView.selectedRange = NSRange(location: textView.text.count, length: 0)
        }
        text = textView.text
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: iOSSubmitTextView

        init(_ parent: iOSSubmitTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            guard replacement == "\n" else { return true }
            parent.text = textView.text
            parent.onSubmit()
            return false
        }
    }
}
