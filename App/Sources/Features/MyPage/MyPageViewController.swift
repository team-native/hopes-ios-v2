import UIKit

@MainActor
final class MyPageViewController: AppPageViewController {
    private let canvas = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
    private let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    private let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    private let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    private let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    private let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    private let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = canvas
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addHeader()
        addProfileCard()
        addStatsCard()
        addMenuCard()
        view.accessibilityIdentifier = "mypage-screen"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func addHeader() {
        let title = styledLabel("마이페이지", size: 28, weight: .bold, color: ink, lineHeight: 38, kern: -0.4)
        let settings = UIButton(type: .system)
        settings.translatesAutoresizingMaskIntoConstraints = false
        settings.backgroundColor = .white
        settings.layer.cornerRadius = 14
        settings.layer.borderWidth = 1
        settings.layer.borderColor = line.cgColor
        settings.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        settings.layer.shadowOpacity = 1
        settings.layer.shadowRadius = 8
        settings.layer.shadowOffset = CGSize(width: 0, height: 4)
        settings.setImage(UIImage(named: "mypage-gear-icon"), for: .normal)
        settings.accessibilityLabel = "설정"
        settings.accessibilityIdentifier = "mypage-settings"
        settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        NSLayoutConstraint.activate([
            settings.widthAnchor.constraint(equalToConstant: 44),
            settings.heightAnchor.constraint(equalToConstant: 44)
        ])

        let header = UIStackView(arrangedSubviews: [title, UIView(), settings])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.isLayoutMarginsRelativeArrangement = true
        header.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)
        contentStack.addArrangedSubview(header)
    }

    private func addProfileCard() {
        let card = makeCard(cornerRadius: 28, shadowRadius: 14, shadowYOffset: 6)
        let profile = UIStackView()
        profile.axis = .horizontal
        profile.alignment = .center
        profile.spacing = 14

        let avatar = UILabel()
        avatar.text = String(UserProfileStore.shared.name.prefix(1))
        avatar.textAlignment = .center
        avatar.font = .systemFont(ofSize: 22, weight: .bold)
        avatar.textColor = blue
        avatar.backgroundColor = softBlue
        avatar.layer.cornerRadius = 28
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 56),
            avatar.heightAnchor.constraint(equalToConstant: 56)
        ])

        let profileText = UIStackView(arrangedSubviews: [
            styledLabel(UserProfileStore.shared.name, size: 18, weight: .medium, color: ink, lineHeight: 26, kern: -0.2),
            styledLabel("\(UserProfileStore.shared.department) · \(UserProfileStore.shared.generation)", size: 14, weight: .medium, color: secondary, lineHeight: 20),
            styledLabel(UserProfileStore.shared.email, size: 12, color: tertiary, lineHeight: 16)
        ])
        profileText.axis = .vertical
        profileText.spacing = 2
        profile.addArrangedSubview(avatar)
        profile.addArrangedSubview(profileText)

        let editButton = UIButton(type: .system)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitle("프로필 수정", for: .normal)
        editButton.setTitleColor(blue, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        editButton.backgroundColor = .white
        editButton.layer.cornerRadius = 10
        editButton.layer.borderWidth = 1
        editButton.layer.borderColor = line.cgColor
        editButton.addTarget(self, action: #selector(editProfile), for: .touchUpInside)
        NSLayoutConstraint.activate([editButton.heightAnchor.constraint(equalToConstant: 36)])

        let content = UIStackView(arrangedSubviews: [profile, editButton])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func addStatsCard() {
        let card = makeCard(cornerRadius: 24, shadowRadius: 10, shadowYOffset: 4)
        let stats = UIStackView()
        stats.axis = .horizontal
        stats.alignment = .center
        stats.distribution = .fill
        stats.translatesAutoresizingMaskIntoConstraints = false
        var statColumns: [UIView] = []
        [
            ("\(CommunityPostStore.shared.myPosts.count)", "작성글"),
            ("\(CommunityPostStore.shared.myComments.count)", "댓글"),
            ("12", "대화")
        ].enumerated().forEach { index, value in
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = line
                divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
                divider.heightAnchor.constraint(equalToConstant: 36).isActive = true
                stats.addArrangedSubview(divider)
            }
            let item = UIStackView(arrangedSubviews: [
                styledLabel(value.0, size: 22, weight: .bold, color: ink, lineHeight: 30, kern: -0.3),
                styledLabel(value.1, size: 12, color: secondary, lineHeight: 16)
            ])
            item.axis = .vertical
            item.alignment = .center
            item.spacing = 2
            stats.addArrangedSubview(item)
            statColumns.append(item)
        }
        NSLayoutConstraint.activate([
            statColumns[0].widthAnchor.constraint(equalTo: statColumns[1].widthAnchor),
            statColumns[1].widthAnchor.constraint(equalTo: statColumns[2].widthAnchor)
        ])
        card.addSubview(stats)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            stats.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stats.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            stats.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            stats.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func addMenuCard() {
        let card = makeCard(cornerRadius: 24, shadowRadius: 10, shadowYOffset: 4)
        let rows = UIStackView()
        rows.axis = .vertical
        rows.alignment = .fill

        let menuItems: [(String, String, String, String, Selector)] = [
            ("mypage-activity-icon", "내 활동", "작성글 · 댓글 모아보기", "mypage-activity", #selector(openActivity)),
            ("mypage-personal-icon", "개인 설정", "AI 답변 스타일 관리", "mypage-personal-settings", #selector(openPersonalSettings)),
            ("mypage-notification-icon", "알림", "새 답변 · 공지", "mypage-notifications", #selector(openNotifications)),
            ("mypage-inquiry-icon", "문의하기", "gsm-chatbot@gsm.hs.kr", "mypage-inquiry", #selector(openInquiry))
        ]
        for (index, item) in menuItems.enumerated() {
            rows.addArrangedSubview(makeMenuRow(icon: item.0, title: item.1, subtitle: item.2, identifier: item.3, action: item.4))
            if index < menuItems.count - 1 {
                let divider = UIView()
                divider.backgroundColor = line
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                rows.addArrangedSubview(divider)
            }
        }

        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func makeMenuRow(icon: String, title: String, subtitle: String, identifier: String, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.accessibilityIdentifier = identifier
        button.accessibilityLabel = "\(title), \(subtitle)"
        button.addTarget(self, action: action, for: .touchUpInside)

        let iconChip = UIView()
        iconChip.translatesAutoresizingMaskIntoConstraints = false
        iconChip.backgroundColor = softBlue
        iconChip.layer.cornerRadius = 12
        let iconView = UIImageView(image: UIImage(named: icon))
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconChip.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconChip.widthAnchor.constraint(equalToConstant: 36),
            iconChip.heightAnchor.constraint(equalToConstant: 36),
            iconView.centerXAnchor.constraint(equalTo: iconChip.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconChip.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])

        let labels = UIStackView(arrangedSubviews: [
            styledLabel(title, size: 15, color: ink, lineHeight: 24, kern: -0.1),
            styledLabel(subtitle, size: 12, color: secondary, lineHeight: 16)
        ])
        labels.axis = .vertical
        labels.spacing = 2
        labels.translatesAutoresizingMaskIntoConstraints = false
        labels.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(named: "mypage-chevron-icon"))
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(iconChip)
        button.addSubview(labels)
        button.addSubview(chevron)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 66),
            iconChip.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            iconChip.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            labels.leadingAnchor.constraint(equalTo: iconChip.trailingAnchor, constant: 12),
            labels.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            labels.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 18),
            chevron.heightAnchor.constraint(equalToConstant: 18)
        ])
        return button
    }

    private func makeCard(cornerRadius: CGFloat, shadowRadius: CGFloat, shadowYOffset: CGFloat) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = cornerRadius
        card.layer.borderWidth = 1
        card.layer.borderColor = line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = shadowRadius
        card.layer.shadowOffset = CGSize(width: 0, height: shadowYOffset)
        return card
    }

    private func styledLabel(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, lineHeight: CGFloat, kern: CGFloat = 0) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern
        ])
        return label
    }

    @objc private func editProfile() {
        push(EditProfileViewController())
    }

    @objc private func openSettings() {
        push(SettingsViewController())
    }

    @objc private func openActivity() {
        push(MyActivityViewController())
    }

    @objc private func openPersonalSettings() {
        push(AIAnswerStyleViewController())
    }

    @objc private func openNotifications() {
        push(NotificationsViewController())
    }

    @objc private func openInquiry() {
        push(InquiryViewController())
    }
}
