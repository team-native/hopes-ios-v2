import UIKit

@MainActor
extension MyPageViewController {
    var profileSummaryText: String {
        let introduction = UserProfileStore.shared.introduction.trimmingCharacters(in: .whitespacesAndNewlines)
        return introduction.isEmpty ? UserProfileStore.shared.email : introduction
    }

    func refreshProfileSummary() {
        profileAvatarLabel?.text = String(UserProfileStore.shared.name.prefix(1))
        profileNameLabel?.attributedText = styledLabel(UserProfileStore.shared.name, size: 18, weight: .medium,
            color: ink, lineHeight: 26, kern: -0.2).attributedText
        profileDepartmentLabel?.attributedText = styledLabel(
            "\(UserProfileStore.shared.department) · \(UserProfileStore.shared.generation)",
            size: 14, weight: .medium, color: secondary, lineHeight: 20
        ).attributedText
        profileSummaryLabel?.attributedText = styledLabel(profileSummaryText, size: 12, color: tertiary,
            lineHeight: 16).attributedText
    }

    func showProfileSaveToast() {
        let check = UIView()
        check.backgroundColor = blue
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

        let message = styledLabel("프로필을 저장했어요", size: 14, weight: .medium, color: .white, lineHeight: 20)
        message.numberOfLines = 1
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
        toast.accessibilityLabel = "프로필을 저장했어요"
        toast.accessibilityIdentifier = "mypage-profile-saved-toast"
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -38),
            toast.widthAnchor.constraint(equalToConstant: 186),
            toast.heightAnchor.constraint(equalToConstant: 50)
        ])
        UIAccessibility.post(notification: .announcement, argument: "프로필을 저장했어요")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak toast] in
            UIView.animate(withDuration: 0.2, animations: {
                toast?.alpha = 0
            }, completion: { _ in
                toast?.removeFromSuperview()
            })
        }
    }
}
