import UIKit

@MainActor
final class SettingsViewController: AppPageViewController {
    private let darkModeSwitch = SettingsToggleControl(frame: .zero)
    private let notificationsSwitch = SettingsToggleControl(frame: .zero)
    private let primaryTextColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    private let secondaryTextColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addHeader()
        addPreferenceCard()
        addInfoCard()
        addLogoutCard()
        addDeleteAccountLink()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func addHeader() {
        let title = AppStyle.label("설정", size: 18, weight: .medium, color: primaryTextColor)
        title.heightAnchor.constraint(equalToConstant: 26).isActive = true
        let subtitle = AppStyle.label("앱 설정과 도움말을 관리해요.", size: 12, color: secondaryTextColor)
        subtitle.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 0

        let back = makeBackButton()
        let header = UIStackView(arrangedSubviews: [back, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addPreferenceCard() {
        let rows = UIStackView()
        rows.axis = .vertical
        rows.addArrangedSubview(makeToggleRow(
            title: "다크 모드",
            subtitle: "시스템 설정에 맞춰 전환",
            iconName: "SettingsMoon",
            toggle: darkModeSwitch,
            key: "settings.darkModeEnabled"
        ))
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeToggleRow(
            title: "알림 받기",
            subtitle: "새 답변 · 공지 알림",
            iconName: "SettingsBell",
            toggle: notificationsSwitch,
            key: "settings.notificationsEnabled",
            defaultValue: true
        ))
        contentStack.addArrangedSubview(makeCard(rows))
    }

    private func addInfoCard() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5"
        let rows = UIStackView()
        rows.axis = .vertical
        rows.addArrangedSubview(makeNavigationRow(
            title: "앱 정보",
            trailing: "v\(version)",
            iconName: "SettingsInfo"
        ) { [weak self] in
            self?.push(AppInfoViewController())
        })
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeNavigationRow(
            title: "개인정보 처리방침",
            iconName: "SettingsInfo"
        ) { [weak self] in
            self?.push(PrivacyPolicyViewController())
        })
        contentStack.addArrangedSubview(makeCard(rows))
    }

    private func addLogoutCard() {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "로그아웃"
        button.accessibilityIdentifier = "settings-logout"
        let icon = UIImageView(image: UIImage(named: "SettingsLogout")?.withRenderingMode(.alwaysOriginal))
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        let label = AppStyle.label(
            "로그아웃",
            size: 15,
            color: UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        )
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        row.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.addAction(UIAction { [weak self] _ in self?.confirmLogout() }, for: .touchUpInside)
        contentStack.addArrangedSubview(makeCard(button, horizontalInset: 16, verticalInset: 0))
    }

    private func makeToggleRow(
        title: String,
        subtitle: String,
        iconName: String,
        toggle: SettingsToggleControl,
        key: String,
        defaultValue: Bool = false
    ) -> UIView {
        let titleLabel = AppStyle.label(title, size: 15, color: primaryTextColor)
        titleLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let subtitleLabel = AppStyle.label(subtitle, size: 12, color: secondaryTextColor)
        subtitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2

        let icon = makeIconChip(iconName: iconName)
        toggle.isOn = UserDefaults.standard.object(forKey: key) as? Bool ?? defaultValue
        toggle.accessibilityLabel = title
        toggle.accessibilityIdentifier = key
        toggle.addAction(UIAction { [weak toggle] _ in
            UserDefaults.standard.set(toggle?.isOn ?? defaultValue, forKey: key)
        }, for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [icon, labels, UIView(), toggle])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        return row
    }

    private func makeNavigationRow(
        title: String,
        trailing: String? = nil,
        iconName: String,
        action: @escaping () -> Void
    ) -> UIView {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .fill
        button.accessibilityLabel = title
        let icon = makeIconChip(iconName: iconName)
        let titleLabel = AppStyle.label(title, size: 15, color: primaryTextColor)
        titleLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let trailingView: UIView
        if let trailing {
            trailingView = AppStyle.label(
                trailing,
                size: 14,
                weight: .medium,
                color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            )
            trailingView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        } else {
            let chevron = UIImageView(image: UIImage(named: "SettingsRight")?.withRenderingMode(.alwaysOriginal))
            chevron.contentMode = .scaleAspectFit
            chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
            chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true
            trailingView = chevron
        }
        let row = UIStackView(arrangedSubviews: [icon, titleLabel, UIView(), trailingView])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        button.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func makeCard(_ content: UIView, horizontalInset: CGFloat = 17, verticalInset: CGFloat = 14) -> UIView {
        let shadow = UIView()
        shadow.layer.cornerRadius = 24
        shadow.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.03).cgColor
        shadow.layer.shadowOpacity = 1
        shadow.layer.shadowRadius = 1.5
        shadow.layer.shadowOffset = CGSize(width: 0, height: 1)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false
        shadow.addSubview(card)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: verticalInset),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: horizontalInset),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -horizontalInset),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -verticalInset),
            card.topAnchor.constraint(equalTo: shadow.topAnchor),
            card.leadingAnchor.constraint(equalTo: shadow.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: shadow.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
        ])
        return shadow
    }

    private func confirmLogout() {
        let alert = UIAlertController(
            title: "로그아웃할까요?",
            message: "다시 로그인하면 대화 기록을 그대로 볼 수 있어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            AuthSessionRouter.logOut()
        })
        present(alert, animated: true)
    }
}

@MainActor
private extension SettingsViewController {
    func makeIconChip(iconName: String) -> UIView {
        let chip = UIView()
        chip.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        chip.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(icon)
        NSLayoutConstraint.activate([
            chip.widthAnchor.constraint(equalToConstant: 36),
            chip.heightAnchor.constraint(equalToConstant: 36),
            icon.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18)
        ])
        return chip
    }

    func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    func makeBackButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "SettingsBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = "뒤로"
        button.accessibilityIdentifier = "settings-back"
        button.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }
}

@MainActor
private final class SettingsToggleControl: UIControl {
    private let imageView = UIImageView()
    var isOn = false {
        didSet {
            guard oldValue != isOn else { return }
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func accessibilityActivate() -> Bool {
        toggle()
        return true
    }

    private func configure() {
        isAccessibilityElement = true
        accessibilityTraits = .toggleButton
        accessibilityHint = "두 번 탭하여 상태를 변경합니다."
        imageView.isAccessibilityElement = false
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 46),
            heightAnchor.constraint(equalToConstant: 44),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 46),
            imageView.heightAnchor.constraint(equalToConstant: 26)
        ])
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        updateAppearance()
    }

    @objc private func toggle() {
        isOn.toggle()
        sendActions(for: .valueChanged)
    }

    private func updateAppearance() {
        let name = isOn ? "SettingsToggleOn" : "SettingsToggleOff"
        imageView.image = UIImage(named: name)?.withRenderingMode(.alwaysOriginal)
        accessibilityValue = isOn ? "켜짐" : "꺼짐"
    }
}

@MainActor
extension SettingsViewController {
    func addDeleteAccountLink() {
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString("회원탈퇴", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: AccountDeletionPalette.tertiary,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]))
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 17, bottom: 2, trailing: 0)
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.accessibilityIdentifier = "settings-delete-account"
        button.heightAnchor.constraint(equalToConstant: 20).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.push(AccountDeletionViewController())
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
    }
}
