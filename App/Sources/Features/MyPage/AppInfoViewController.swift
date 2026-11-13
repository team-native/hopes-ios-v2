import UIKit

@MainActor
final class AppInfoViewController: AppPageViewController {
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
        addAppIdentity()
        addDetailsCard()
        let footer = AppStyle.label(
            "광주소프트웨어마이스터고 · hopes",
            size: 12,
            color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        )
        footer.textAlignment = .center
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footer)
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addHeader() {
        let title = AppStyle.label("앱 정보", size: 18, weight: .medium)
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = UIColor(red: 54 / 255, green: 66 / 255, blue: 85 / 255, alpha: 1)
        back.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        back.widthAnchor.constraint(equalToConstant: 44).isActive = true
        back.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let header = UIStackView(arrangedSubviews: [back, title])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addAppIdentity() {
        let tile = UIView()
        tile.backgroundColor = .white
        tile.layer.cornerRadius = 18
        tile.layer.borderWidth = 1
        tile.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        tile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        tile.layer.shadowOpacity = 1
        tile.layer.shadowRadius = 8
        tile.layer.shadowOffset = CGSize(width: 0, height: 4)
        let logo = UIImageView(image: UIImage(named: "auth-logo-mark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(logo)
        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: 80),
            tile.heightAnchor.constraint(equalToConstant: 80),
            logo.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 32),
            logo.heightAnchor.constraint(equalToConstant: 50)
        ])

        let name = AppStyle.label("hopes", size: 22, weight: .bold)
        name.textAlignment = .center
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5"
        let versionLabel = AppStyle.label("버전 \(version)", size: 14, weight: .medium, color: AppStyle.muted)
        versionLabel.textAlignment = .center
        let identity = UIStackView(arrangedSubviews: [tile, name, versionLabel])
        identity.axis = .vertical
        identity.alignment = .center
        identity.spacing = 10
        identity.isLayoutMarginsRelativeArrangement = true
        identity.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0)
        contentStack.addArrangedSubview(identity)
    }

    private func addDetailsCard() {
        let rows = UIStackView()
        rows.axis = .vertical
        rows.addArrangedSubview(makeValueRow(title: "최신 버전", value: "사용 중"))
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeLinkRow(title: "오픈소스 라이선스") { [weak self] in
            self?.showMessage("이 앱에는 별도로 등록된 외부 오픈소스 패키지가 없습니다.")
        })
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeLinkRow(title: "이용약관") { [weak self] in
            self?.showMessage("이용약관 문서를 준비 중입니다.")
        })
        rows.addArrangedSubview(makeDivider())
        rows.addArrangedSubview(makeValueRow(title: "문의", value: "gsm-chatbot@gsm.hs.kr"))

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 2),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -2)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func makeValueRow(title: String, value: String) -> UIView {
        let valueLabel = AppStyle.label(
            value,
            size: 14,
            weight: .medium,
            color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        )
        let row = UIStackView(arrangedSubviews: [AppStyle.label(title, size: 15), UIView(), valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        row.isLayoutMarginsRelativeArrangement = true
        return row
    }

    private func makeLinkRow(title: String, action: @escaping () -> Void) -> UIView {
        let button = UIButton(type: .system)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        let label = AppStyle.label(title, size: 15)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
        let row = UIStackView(arrangedSubviews: [label, UIView(), chevron])
        row.axis = .horizontal
        row.alignment = .center
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
        return button
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }
}
