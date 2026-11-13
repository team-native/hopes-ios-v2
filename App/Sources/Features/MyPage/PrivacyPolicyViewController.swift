import UIKit

@MainActor
final class PrivacyPolicyViewController: AppPageViewController {
    private let sections = [
        ("1. 수집하는 정보", "학교 이메일, 이름, 과, 기수, 자기소개, 대화 내용"),
        ("2. 이용 목적", "AI 답변 제공과 개인화, 커뮤니티 운영"),
        ("3. 보관 기간", "회원 탈퇴 시까지 (세부 기간 확정 필요)"),
        ("4. 위치 정보", "위치는 답변에만 사용하고 저장하지 않아요")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        contentStack.spacing = 14
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addHeader()
        addPolicyCard()
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
        let title = AppStyle.label("개인정보 처리방침", size: 18, weight: .medium)
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

    private func addPolicyCard() {
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 12
        let draftNotice = AppStyle.label(
            "본문은 확정된 처리방침 문서로 교체하세요.",
            size: 12,
            color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        )
        content.addArrangedSubview(draftNotice)
        for section in sections {
            content.addArrangedSubview(AppStyle.label(section.0, size: 15, weight: .medium))
            content.addArrangedSubview(AppStyle.label(section.1, size: 14, weight: .medium, color: AppStyle.muted))
        }

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
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(card)
    }
}
