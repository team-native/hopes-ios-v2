import UIKit

@MainActor
final class MyPageViewController: AppPageViewController {
    private let profileNameLabel = AppStyle.label("", size: 20, weight: .bold)
    private let profileDetailLabel = AppStyle.label("", size: 13, color: AppStyle.muted)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "마이페이지"
        addProfileCard()
        addActivityCard()

        addSection("내 활동")
        addRow("작성글 · 댓글 모아보기", subtitle: "내가 남긴 글과 댓글을 확인해요", symbol: "text.bubble") { [weak self] in
            self?.showMessage("내 활동 화면은 별도 페이지 이슈에서 연결할게요")
        }

        addSection("개인 설정")
        addRow("AI 답변 스타일 관리", subtitle: "답변 방식과 관심 분야를 설정해요", symbol: "sparkles") { [weak self] in
            self?.push(AIAnswerStyleViewController())
        }
        addRow("알림", subtitle: "새 답변 · 공지", symbol: "bell") { [weak self] in
            self?.push(NotificationsViewController())
        }
        addRow("문의하기", subtitle: "gsm-chatbot@gsm.hs.kr", symbol: "envelope") { [weak self] in
            self?.push(InquiryViewController())
        }
        addRow("프로필 수정", symbol: "person.crop.circle") { [weak self] in
            self?.openProfileEditor()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        profileNameLabel.text = UserProfileStore.shared.name
        profileDetailLabel.text = "\(UserProfileStore.shared.department) · 10기\n\(UserProfileStore.shared.email)"
    }

    private func addProfileCard() {
        let card = AppStyle.card()
        let avatar = UIImageView(image: UIImage(systemName: "person.fill"))
        avatar.tintColor = AppStyle.blue
        avatar.backgroundColor = AppStyle.paleBlue
        avatar.contentMode = .center
        avatar.layer.cornerRadius = 28
        avatar.clipsToBounds = true
        avatar.widthAnchor.constraint(equalToConstant: 56).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 56).isActive = true

        profileNameLabel.text = UserProfileStore.shared.name
        profileDetailLabel.text = "\(UserProfileStore.shared.department) · 10기\n\(UserProfileStore.shared.email)"
        let userInfo = UIStackView(arrangedSubviews: [profileNameLabel, profileDetailLabel])
        userInfo.axis = .vertical
        userInfo.spacing = 5
        let header = UIStackView(arrangedSubviews: [avatar, userInfo])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 14
        header.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18)
        ])

        let edit = UIButton(type: .system)
        edit.setTitle("프로필 수정", for: .normal)
        edit.setTitleColor(AppStyle.blue, for: .normal)
        edit.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        edit.addAction(UIAction { [weak self] _ in
            self?.openProfileEditor()
        }, for: .touchUpInside)
        edit.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(edit)
        NSLayoutConstraint.activate([
            edit.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            edit.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            edit.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func openProfileEditor() {
        push(EditProfileViewController())
    }

    private func addActivityCard() {
        let card = AppStyle.card()
        let stats: [(String, String)] = [("2", "작성글"), ("5", "댓글"), ("12", "대화")]
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        stats.forEach { value, title in
            let number = AppStyle.label(value, size: 20, weight: .bold)
            number.textAlignment = .center
            let label = AppStyle.label(title, size: 13, color: AppStyle.muted)
            label.textAlignment = .center
            let column = UIStackView(arrangedSubviews: [number, label])
            column.axis = .vertical
            column.spacing = 5
            row.addArrangedSubview(column)
        }
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        contentStack.addArrangedSubview(card)
    }
}
