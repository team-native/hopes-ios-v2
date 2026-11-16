import UIKit

@MainActor
final class CommunityWriteKeyboardLayout {
    private let hostView: UIView
    private let bodyHeightConstraint: NSLayoutConstraint
    private let privacyNotice: UIView
    private var keyboardObserver: NSObjectProtocol?

    init(
        view: UIView,
        header: UIStackView,
        scrollView: UIScrollView,
        bodyView: UITextView,
        privacyNotice: UIView
    ) {
        hostView = view
        self.privacyNotice = privacyNotice
        bodyHeightConstraint = bodyView.heightAnchor.constraint(equalToConstant: 511)

        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        view.constraints
            .filter { $0.firstItem === scrollView && ($0.firstAttribute == .top || $0.firstAttribute == .bottom) }
            .forEach { $0.isActive = false }
        view.keyboardLayoutGuide.followsUndockedKeyboard = false

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            header.heightAnchor.constraint(equalToConstant: 44),
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            bodyHeightConstraint
        ])
        observeKeyboard()
    }

    deinit {
        if let keyboardObserver { NotificationCenter.default.removeObserver(keyboardObserver) }
    }

    private func observeKeyboard() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self,
                      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[
                        UIResponder.keyboardAnimationDurationUserInfoKey
                      ] as? TimeInterval
                else { return }
                let keyboardFrame = self.hostView.convert(frame, from: nil)
                let isVisible = keyboardFrame.minY < self.hostView.bounds.maxY &&
                    keyboardFrame.maxY > self.hostView.bounds.maxY - 1
                self.bodyHeightConstraint.constant = isVisible ? 120 : 511
                self.privacyNotice.isHidden = isVisible
                UIView.animate(withDuration: duration) {
                    self.hostView.layoutIfNeeded()
                }
            }
        }
    }
}
