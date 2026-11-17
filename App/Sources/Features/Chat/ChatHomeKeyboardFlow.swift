import UIKit

@MainActor
extension ChatHomeViewController {
    func fillQuestion(_ question: String) {
        messageField.text = question
        messageField.becomeFirstResponder()
    }

    func observeKeyboardCollapse() {
        NotificationCenter.default.addObserver(self, selector: #selector(homeKeyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func stopObservingKeyboardCollapse() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func homeKeyboardWillShow() {
        setKeyboardCollapsed(true)
    }

    @objc private func homeKeyboardWillHide() {
        setKeyboardCollapsed(false)
    }

    func setKeyboardCollapsed(_ collapsed: Bool) {
        guard let header = contentStack.arrangedSubviews.first else { return }
        if keyboardHint.superview == nil {
            keyboardHint.heightAnchor.constraint(equalToConstant: 16).isActive = true
            keyboardHint.isHidden = true
            keyboardHint.accessibilityIdentifier = "chat-home-keyboard-hint"
            contentStack.insertArrangedSubview(keyboardHint, at: 1)
        }
        guard collapsed == hiddenStatesBeforeKeyboard.isEmpty else { return }
        let others = contentStack.arrangedSubviews.filter { $0 !== header && $0 !== keyboardHint }
        if collapsed {
            for view in others {
                hiddenStatesBeforeKeyboard[ObjectIdentifier(view)] = view.isHidden
                view.isHidden = true
            }
            contentStack.setCustomSpacing(12, after: header)
        } else {
            for view in others {
                view.isHidden = hiddenStatesBeforeKeyboard[ObjectIdentifier(view)] ?? false
            }
            hiddenStatesBeforeKeyboard.removeAll()
            contentStack.setCustomSpacing(contentStack.spacing, after: header)
        }
        keyboardHint.isHidden = !collapsed
    }
}
