import UIKit

@MainActor
final class PrivacySettingsViewController: AppPageViewController {
    private let usageSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "개인정보 설정"
        addHeading("개인정보와 계정", subtitle: "Hopes에서 사용하는 정보와 계정을 관리해요")

        addSection("데이터 설정")
        let usageRow = UIStackView()
        usageRow.axis = .horizontal
        usageRow.alignment = .center
        usageRow.spacing = 12
        let description = UIStackView(arrangedSubviews: [
            AppStyle.label("서비스 개선을 위한 이용 정보", size: 15, weight: .semibold),
            AppStyle.label("앱 품질 개선 목적으로 사용 정보를 저장해요", size: 12, color: AppStyle.muted)
        ])
        description.axis = .vertical
        description.spacing = 5
        usageRow.addArrangedSubview(description)
        usageRow.addArrangedSubview(UIView())
        usageSwitch.isOn = UserDefaults.standard.bool(forKey: "privacy.usageDataEnabled")
        usageSwitch.addAction(UIAction { [weak self] _ in
            UserDefaults.standard.set(self?.usageSwitch.isOn ?? false, forKey: "privacy.usageDataEnabled")
        }, for: .valueChanged)
        usageRow.addArrangedSubview(usageSwitch)
        let usageCard = AppStyle.card()
        usageRow.translatesAutoresizingMaskIntoConstraints = false
        usageCard.addSubview(usageRow)
        NSLayoutConstraint.activate([
            usageRow.topAnchor.constraint(equalTo: usageCard.topAnchor, constant: 16),
            usageRow.leadingAnchor.constraint(equalTo: usageCard.leadingAnchor, constant: 16),
            usageRow.trailingAnchor.constraint(equalTo: usageCard.trailingAnchor, constant: -16),
            usageRow.bottomAnchor.constraint(equalTo: usageCard.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(usageCard)

        addSection("안내")
        addRow("개인정보 처리방침", symbol: "doc.text") { [weak self] in
            self?.showMessage("개인정보 처리방침 문서는 서비스 출시 전에 연결할게요")
        }
        addRow("앱 버전", subtitle: "Hopes 2.0.0", symbol: "info.circle") { [weak self] in
            self?.showMessage("최신 버전을 사용하고 있어요")
        }

        addSection("계정")
        addRow("로그아웃", symbol: "rectangle.portrait.and.arrow.right") { [weak self] in self?.logout() }
        addRow("계정 삭제", symbol: "trash") { [weak self] in self?.confirmAccountDeletion() }
    }

    private func logout() {
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

    private func confirmAccountDeletion() {
        let alert = UIAlertController(title: "계정을 삭제할까요?", message: "계정 삭제 API 연결 전에는 실제 계정이 삭제되지 않아요.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제 요청", style: .destructive) { [weak self] _ in
            self?.showMessage("계정 삭제 요청 화면을 준비했어요. 삭제 API가 연결되지 않아 실제 삭제는 진행되지 않았어요")
        })
        present(alert, animated: true)
    }
}
