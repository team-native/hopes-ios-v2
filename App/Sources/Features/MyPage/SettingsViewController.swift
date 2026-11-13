import UIKit

@MainActor
final class SettingsViewController: AppPageViewController {
    private let darkModeSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 18
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 14
        }
        addSettingsHeader()

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 3
        rows.addArrangedSubview(makeLinkRow(
            title: "개인 설정",
            subtitle: "시스템 프롬프트 관리",
            action: { [weak self] in self?.push(AIAnswerStyleViewController()) }
        ))
        rows.addArrangedSubview(makeLinkRow(
            title: "문의하기",
            subtitle: "gsm-chatbot@gsm.hs.kr",
            action: { [weak self] in self?.push(InquiryViewController()) }
        ))
        let rowsContainer = centered(rows, width: 314)
        contentStack.addArrangedSubview(rowsContainer)
        contentStack.setCustomSpacing(28, after: rowsContainer)

        let darkModeContainer = centered(makeDarkModeRow(), width: 314)
        contentStack.addArrangedSubview(darkModeContainer)
        contentStack.setCustomSpacing(26, after: darkModeContainer)

        let logout = UIButton(type: .system)
        logout.setTitle("로그아웃", for: .normal)
        logout.setTitleColor(UIColor(red: 224 / 255, green: 33 / 255, blue: 28 / 255, alpha: 1), for: .normal)
        logout.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        logout.backgroundColor = UIColor(red: 1, green: 237 / 255, blue: 237 / 255, alpha: 1)
        logout.layer.cornerRadius = 14
        logout.layer.borderWidth = 1
        logout.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        logout.heightAnchor.constraint(equalToConstant: 45).isActive = true
        logout.addAction(UIAction { [weak self] _ in self?.confirmLogout() }, for: .touchUpInside)
        contentStack.addArrangedSubview(centered(logout, width: 330))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func addSettingsHeader() {
        let titleLabel = AppStyle.label("설정", size: 27, weight: .bold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let subtitleLabel = AppStyle.label("앱 설정과 도움말을 관리해요.", size: 13, color: UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 4

        let profileButton = UIButton(type: .system)
        profileButton.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
        profileButton.tintColor = UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1)
        profileButton.accessibilityLabel = "프로필 관리"
        profileButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        profileButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        profileButton.addAction(UIAction { [weak self] _ in
            self?.push(EditProfileViewController())
        }, for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [labels, UIView(), profileButton])
        header.axis = .horizontal
        header.alignment = .center
        contentStack.addArrangedSubview(header)
    }

    private func centered(_ view: UIView, width: CGFloat) -> UIView {
        let container = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.widthAnchor.constraint(equalToConstant: width),
            view.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor)
        ])
        return container
    }

    private func makeLinkRow(title: String, subtitle: String, action: @escaping () -> Void) -> UIView {
        let titleLabel = AppStyle.label(title, size: 15, weight: .semibold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let subtitleLabel = AppStyle.label(subtitle, size: 12, color: UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 4

        let open = UIButton(type: .system)
        open.setTitle("열기", for: .normal)
        open.setTitleColor(UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1), for: .normal)
        open.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        open.backgroundColor = .white
        open.layer.cornerRadius = 14
        open.layer.borderWidth = 1
        open.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        open.widthAnchor.constraint(equalToConstant: 48).isActive = true
        open.heightAnchor.constraint(equalToConstant: 32).isActive = true
        open.addAction(UIAction { _ in action() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [labels, UIView(), open])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10)
        row.backgroundColor = .white
        row.layer.cornerRadius = 14
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        row.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return row
    }

    private func makeDarkModeRow() -> UIView {
        let titleLabel = AppStyle.label("다크 모드", size: 16, weight: .semibold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let subtitleLabel = AppStyle.label("시스템 설정에 맞춰 전환", size: 12, color: UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 5
        darkModeSwitch.isOn = UserDefaults.standard.bool(forKey: "settings.darkModeEnabled")
        darkModeSwitch.addAction(UIAction { [weak self] _ in
            UserDefaults.standard.set(self?.darkModeSwitch.isOn ?? false, forKey: "settings.darkModeEnabled")
        }, for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [labels, UIView(), darkModeSwitch])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 12)
        row.backgroundColor = .white
        row.layer.cornerRadius = 18
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        row.layer.shadowColor = UIColor(red: 13 / 255, green: 26 / 255, blue: 46 / 255, alpha: 0.07).cgColor
        row.layer.shadowOpacity = 1
        row.layer.shadowRadius = 8
        row.layer.shadowOffset = CGSize(width: 0, height: 6)
        row.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return row
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
