import UIKit

@MainActor
extension ChatConversationViewController {
    func showToast(_ message: String) {
        dismissSuccessToast()
        let toast = makeSuccessToast(message: message)
        successToastView = toast
        view.addSubview(toast)
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 6)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            toast.alpha = 1
            toast.transform = .identity
        }
        UIAccessibility.post(notification: .announcement, argument: message)
        scheduleSuccessToastDismissal(for: toast)
    }

    func dismissSuccessToast() {
        successToastDismissal?.cancel()
        successToastDismissal = nil
        successToastView?.removeFromSuperview()
        successToastView = nil
    }

    private func makeSuccessToast(message: String) -> UIView {
        let toast = UIView()
        toast.backgroundColor = AppStyle.ink
        toast.layer.cornerRadius = 25
        toast.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        toast.layer.shadowOpacity = 1
        toast.layer.shadowRadius = 14
        toast.layer.shadowOffset = CGSize(width: 0, height: 6)
        toast.isAccessibilityElement = true
        toast.accessibilityLabel = message
        toast.accessibilityIdentifier = "chat-success-toast"
        toast.isUserInteractionEnabled = false

        let checkBackground = UIView()
        checkBackground.backgroundColor = AppStyle.blue
        checkBackground.layer.cornerRadius = 11
        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = .white
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        checkBackground.addSubview(check)
        NSLayoutConstraint.activate([
            checkBackground.widthAnchor.constraint(equalToConstant: 22),
            checkBackground.heightAnchor.constraint(equalToConstant: 22),
            check.widthAnchor.constraint(equalToConstant: 12),
            check.heightAnchor.constraint(equalToConstant: 12),
            check.centerXAnchor.constraint(equalTo: checkBackground.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: checkBackground.centerYAnchor)
        ])

        let label = AppStyle.label(message, size: 14, color: .white)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let content = UIStackView(arrangedSubviews: [checkBackground, label])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: toast.topAnchor),
            content.leadingAnchor.constraint(equalTo: toast.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: toast.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: toast.bottomAnchor),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32)
        ])
        toast.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -100).isActive = true
        return toast
    }

    private func scheduleSuccessToastDismissal(for toast: UIView) {
        let dismissal = DispatchWorkItem { [weak self, weak toast] in
            guard let self, let toast, self.successToastView === toast else { return }
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
                toast.alpha = 0
                toast.transform = CGAffineTransform(translationX: 0, y: 6)
            } completion: { [weak self, weak toast] _ in
                toast?.removeFromSuperview()
                if self?.successToastView === toast {
                    self?.successToastView = nil
                    self?.successToastDismissal = nil
                }
            }
        }
        successToastDismissal = dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: dismissal)
    }
}
