import UIKit

@MainActor
extension EditProfileViewController {
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let frame = view.convert(keyboardFrame, from: nil)
        let isVisible = frame.minY < view.bounds.maxY && frame.height > 0

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.updateKeyboardLayout(isVisible, keyboardTop: frame.minY)
            self.view.layoutIfNeeded()
            if isVisible {
                let focusedRect: CGRect?
                if self.introductionView.isFirstResponder {
                    focusedRect = self.introductionView.convert(self.introductionView.bounds, to: self.scrollView)
                } else if self.nameField.isFirstResponder {
                    focusedRect = self.nameField.convert(self.nameField.bounds, to: self.scrollView)
                } else {
                    focusedRect = nil
                }
                if let focusedRect {
                    self.scrollView.scrollRectToVisible(focusedRect.insetBy(dx: 0, dy: -12), animated: false)
                }
            }
        }
    }

    private func updateKeyboardLayout(_ isVisible: Bool, keyboardTop: CGFloat) {
        guard let saveButton else { return }

        if isVisible, !isKeyboardLayoutActive {
            isKeyboardLayoutActive = true
            saveButtonBottomConstraint?.isActive = false
            saveButtonLeadingConstraint?.isActive = false
            saveButtonTrailingConstraint?.isActive = false
            saveButton.removeFromSuperview()
            contentStack.addArrangedSubview(saveButton)
            scrollBottomConstraint?.isActive = false
            keyboardScrollBottomConstraint = scrollView.bottomAnchor.constraint(
                equalTo: view.topAnchor,
                constant: keyboardTop
            )
            keyboardScrollBottomConstraint?.isActive = true
        } else if !isVisible, isKeyboardLayoutActive {
            isKeyboardLayoutActive = false
            contentStack.removeArrangedSubview(saveButton)
            saveButton.removeFromSuperview()
            view.addSubview(saveButton)
            keyboardScrollBottomConstraint?.isActive = false
            saveButtonBottomConstraint?.isActive = true
            saveButtonLeadingConstraint?.isActive = true
            saveButtonTrailingConstraint?.isActive = true
            scrollBottomConstraint?.isActive = true
        }

        if isVisible {
            keyboardScrollBottomConstraint?.constant = keyboardTop
            let useCompactLayout = introductionView.isFirstResponder
            if useCompactLayout != isCompactKeyboardLayoutActive {
                isCompactKeyboardLayoutActive = useCompactLayout
                contentStack.spacing = useCompactLayout ? 14 : 16
                contentTopConstraint?.constant = useCompactLayout ? 8 : 12
                accountCard?.isHidden = useCompactLayout
                profileSectionHeading?.isHidden = useCompactLayout
            }
        } else if isCompactKeyboardLayoutActive {
            isCompactKeyboardLayoutActive = false
            contentStack.spacing = showsSaveError ? 14 : 16
            contentTopConstraint?.constant = showsSaveError ? 10 : 12
            accountCard?.isHidden = false
            profileSectionHeading?.isHidden = false
        }
    }
}
