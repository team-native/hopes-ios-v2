import UIKit

@MainActor
extension AIAnswerStyleViewController: UITextViewDelegate {
    private func placeSaveButtonInContent() {
        NSLayoutConstraint.deactivate(saveButtonConstraints)
        saveButtonConstraints.removeAll()
        saveButton.removeFromSuperview()
        contentStack.addArrangedSubview(saveButton)
    }

    private func restoreSaveButtonToBottom() {
        contentStack.removeArrangedSubview(saveButton)
        saveButton.removeFromSuperview()
        pinSaveButtonToBottom()
    }

    private func enterKeyboardLayout(overlap: CGFloat) {
        guard !keyboardLayoutIsActive, let headerView else {
            scrollBottomConstraint?.constant = -overlap
            return
        }
        keyboardLayoutIsActive = true
        contentStack.removeArrangedSubview(headerView)
        headerView.removeFromSuperview()
        view.addSubview(headerView)
        pinnedHeaderConstraints = [
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 44)
        ]
        NSLayoutConstraint.activate(pinnedHeaderConstraints)

        scrollTopConstraint?.isActive = false
        scrollTopConstraint = scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4)
        scrollTopConstraint?.isActive = true
        scrollBottomConstraint?.constant = -overlap
        topSaveButton.isHidden = true
        promptHeightConstraint.constant = 140
        promptView.layer.borderWidth = 1.5
        promptView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
        contentStack.spacing = 14
        placeSaveButtonInContent()
    }

    private func exitKeyboardLayout() {
        guard keyboardLayoutIsActive, let headerView else {
            scrollBottomConstraint?.constant = 0
            return
        }
        keyboardLayoutIsActive = false
        restoreSaveButtonToBottom()
        NSLayoutConstraint.deactivate(pinnedHeaderConstraints)
        pinnedHeaderConstraints.removeAll()
        headerView.removeFromSuperview()
        contentStack.insertArrangedSubview(headerView, at: 0)

        scrollTopConstraint?.isActive = false
        scrollTopConstraint = scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        scrollTopConstraint?.isActive = true
        scrollBottomConstraint?.constant = 0
        topSaveButton.isHidden = false
        promptHeightConstraint.constant = 220
        promptView.layer.borderWidth = 1
        promptView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        contentStack.spacing = 16
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderWidth = 1.5
        textView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
    }

    func textViewDidChange(_ textView: UITextView) {
        promptPlaceholder.isHidden = !textView.text.isEmpty
    }

    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let frame = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - frame.minY)
        if overlap > view.safeAreaInsets.bottom {
            enterKeyboardLayout(overlap: overlap)
        } else {
            exitKeyboardLayout()
        }

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }

    func showSavedToast() {
        let check = UIView()
        check.backgroundColor = AppStyle.blue
        check.layer.cornerRadius = 11
        check.widthAnchor.constraint(equalToConstant: 22).isActive = true
        check.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let checkmark = UIImageView(image: UIImage(named: "ProfileSaveToastCheck")?.withRenderingMode(.alwaysOriginal))
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        check.addSubview(checkmark)
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: check.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: check.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 14),
            checkmark.heightAnchor.constraint(equalToConstant: 14)
        ])

        let message = AppStyle.label("다음 답변부터 반영돼요", size: 14, weight: .medium, color: .white)
        let toast = UIStackView(arrangedSubviews: [check, message])
        toast.axis = .horizontal
        toast.alignment = .center
        toast.spacing = 10
        toast.isLayoutMarginsRelativeArrangement = true
        toast.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 18)
        toast.backgroundColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 0.92)
        toast.layer.cornerRadius = 25
        toast.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        toast.layer.shadowOpacity = 1
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 8)
        toast.accessibilityLabel = "다음 답변부터 반영돼요"
        toast.accessibilityIdentifier = "ai-answer-style-saved-toast"
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -37),
            toast.widthAnchor.constraint(equalToConstant: 203),
            toast.heightAnchor.constraint(equalToConstant: 50)
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak toast] in
            UIView.animate(withDuration: 0.2, animations: {
                toast?.alpha = 0
            }, completion: { _ in
                toast?.removeFromSuperview()
            })
        }
    }
}
