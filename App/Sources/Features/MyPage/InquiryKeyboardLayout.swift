import UIKit

@MainActor
extension InquiryViewController {
    func enterKeyboardLayout(overlap: CGFloat) {
        guard !keyboardLayoutIsActive, let headerView, let submitButton else {
            scrollBottomConstraint?.constant = -overlap
            return
        }
        keyboardLayoutIsActive = true
        contentStack.removeArrangedSubview(headerView)
        headerView.removeFromSuperview()
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
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

        NSLayoutConstraint.deactivate(submitButtonConstraints)
        submitButtonConstraints.removeAll()
        submitButton.removeFromSuperview()
        contentStack.addArrangedSubview(submitButton)
        scrollBottomConstraint?.constant = -overlap
        scrollBottomConstraint?.isActive = true
        mailInfoRow.isHidden = true
        emailHeightConstraint.constant = 54
        messageMinimumHeightConstraint.constant = 54
        messageHeightConstraint.constant = 54
        contentStack.spacing = 14
    }

    func exitKeyboardLayout() {
        guard keyboardLayoutIsActive, let headerView, let submitButton else {
            scrollBottomConstraint?.constant = 0
            return
        }
        keyboardLayoutIsActive = false
        contentStack.removeArrangedSubview(submitButton)
        submitButton.removeFromSuperview()
        scrollBottomConstraint?.isActive = false
        scrollBottomConstraint?.constant = 0
        pinSubmitButtonToBottom()

        NSLayoutConstraint.deactivate(pinnedHeaderConstraints)
        pinnedHeaderConstraints.removeAll()
        headerView.removeFromSuperview()
        contentStack.insertArrangedSubview(headerView, at: 0)
        scrollTopConstraint?.isActive = false
        scrollTopConstraint = scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        scrollTopConstraint?.isActive = true

        mailInfoRow.isHidden = false
        emailHeightConstraint.constant = 56
        let normalMessageHeight: CGFloat = hasMessageError ? 150 : 160
        messageMinimumHeightConstraint.constant = normalMessageHeight
        messageHeightConstraint.constant = normalMessageHeight
        contentStack.spacing = 16
    }
}
