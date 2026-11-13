import UIKit

@MainActor
final class SettingsViewController: AppPageViewController {
    private let darkModeSwitch = UISwitch()
    private let notificationsSwitch = UISwitch()

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
        let title = AppStyle.label("설정", size: 18, weight: .medium)
        title.textColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        let subtitle = AppStyle.label("앱 설정과 도움말을 관리해요.", size: 12, color: AppStyle.muted)
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
            symbol: "moon",
            toggle: darkModeSwitch,
            key: "settings.darkModeEnabled"
        ))
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeToggleRow(
            title: "알림 받기",
            subtitle: "새 답변 · 공지 알림",
            symbol: "bell",
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
        rows.addArrangedSubview(makeNavigationRow(title: "앱 정보", trailing: "v\(version)") { [weak self] in
            self?.push(AppInfoViewController())
        })
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeNavigationRow(title: "개인정보 처리방침", symbol: "chevron.right") { [weak self] in
            self?.push(PrivacyPolicyViewController())
        })
        contentStack.addArrangedSubview(makeCard(rows))
    }

    private func addLogoutCard() {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .leading
        button.setTitle("  로그아웃", for: .normal)
        button.setTitleColor(UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1), for: .normal)
        button.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        button.tintColor = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.addAction(UIAction { [weak self] _ in self?.confirmLogout() }, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        contentStack.addArrangedSubview(makeCard(button, horizontalInset: 16, verticalInset: 0))
    }

    private func makeToggleRow(
        title: String,
        subtitle: String,
        symbol: String,
        toggle: UISwitch,
        key: String,
        defaultValue: Bool = false
    ) -> UIView {
        let titleLabel = AppStyle.label(title, size: 15)
        let subtitleLabel = AppStyle.label(subtitle, size: 12, color: AppStyle.muted)
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2

        let icon = makeIconChip(symbol: symbol)
        toggle.isOn = UserDefaults.standard.object(forKey: key) as? Bool ?? defaultValue
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
        symbol: String? = nil,
        action: @escaping () -> Void
    ) -> UIView {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .fill
        let titleLabel = AppStyle.label(title, size: 15)
        let trailingView: UIView
        if let trailing {
            trailingView = AppStyle.label(
                trailing,
                size: 14,
                weight: .medium,
                color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            )
        } else {
            let chevron = UIImageView(image: UIImage(systemName: symbol ?? "chevron.right"))
            chevron.tintColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            chevron.contentMode = .scaleAspectFit
            chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
            trailingView = chevron
        }
        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), trailingView])
        row.axis = .horizontal
        row.alignment = .center
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

    private func makeIconChip(symbol: String) -> UIView {
        let chip = UIView()
        chip.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        chip.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
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

    private func makeCard(_ content: UIView, horizontalInset: CGFloat = 17, verticalInset: CGFloat = 14) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: verticalInset),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: horizontalInset),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -horizontalInset),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -verticalInset)
        ])
        return card
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private func makeBackButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = UIColor(red: 54 / 255, green: 66 / 255, blue: 85 / 255, alpha: 1)
        button.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    private func confirmLogout() {
        let alert = UIAlertController(title: "로그아웃", message: "로그아웃할까요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            window.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window.makeKeyAndVisible()
        })
        present(alert, animated: true)
    }
}
