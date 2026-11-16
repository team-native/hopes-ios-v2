import UIKit

@MainActor
enum AppToast {
    static func show(_ message: String, in view: UIView, bottomInset: CGFloat, duration: TimeInterval = 2) {
        let check = UIView()
        check.backgroundColor = AppStyle.blue
        check.layer.cornerRadius = 11
        let checkmark = UIImageView(image: UIImage(named: "ProfileSaveToastCheck")?.withRenderingMode(.alwaysOriginal))
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        check.addSubview(checkmark)

        let label = AppStyle.label(message, size: 14, weight: .medium, color: .white)
        label.numberOfLines = 1
        let toast = UIStackView(arrangedSubviews: [check, label])
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
        toast.accessibilityLabel = message
        toast.accessibilityIdentifier = "app-toast"
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            check.widthAnchor.constraint(equalToConstant: 22),
            check.heightAnchor.constraint(equalToConstant: 22),
            checkmark.centerXAnchor.constraint(equalTo: check.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: check.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 14),
            checkmark.heightAnchor.constraint(equalToConstant: 14),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomInset),
            toast.heightAnchor.constraint(equalToConstant: 50)
        ])
        UIAccessibility.post(notification: .announcement, argument: message)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak toast] in
            UIView.animate(withDuration: 0.2, animations: { toast?.alpha = 0 }, completion: { _ in
                toast?.removeFromSuperview()
            })
        }
    }
}
