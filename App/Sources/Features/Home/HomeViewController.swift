import UIKit

@MainActor
final class HomeViewController: AppPageViewController {
    private let suggestedQuestions = [
        "기숙사 생활은 어떤가요?",
        "전공 수업은 어떻게 진행되나요?",
        "동아리는 어떻게 선택하나요?"
    ]

    private let popularPosts = [
        ("기숙사 준비물 뭐 챙겨가면 좋나요?", "답글 8 · 오늘"),
        ("이번 학기 동아리 모집 일정", "답글 5 · 어제")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "홈"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(openNotifications)
        )

        addHeading("안녕하세요, 시우님 👋", subtitle: "오늘도 궁금한 걸 편하게 물어보세요")
        addQuestionCard()

        addSection("이런 질문은 어때요?")
        suggestedQuestions.forEach { question in
            addRow(question, symbol: "arrow.up.right") { [weak self] in
                self?.openChat()
            }
        }

        let popularHeader = UIStackView()
        popularHeader.axis = .horizontal
        popularHeader.alignment = .center
        let title = AppStyle.label("커뮤니티 인기 글", size: 18, weight: .bold)
        let more = UIButton(type: .system)
        more.setTitle("전체 보기", for: .normal)
        more.setTitleColor(AppStyle.blue, for: .normal)
        more.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        more.addAction(UIAction { [weak self] _ in self?.openCommunity() }, for: .touchUpInside)
        popularHeader.addArrangedSubview(title)
        popularHeader.addArrangedSubview(UIView())
        popularHeader.addArrangedSubview(more)
        contentStack.addArrangedSubview(popularHeader)

        popularPosts.forEach { post in
            addRow(post.0, subtitle: post.1, symbol: "text.bubble") { [weak self] in
                self?.openCommunity()
            }
        }
    }

    private func addQuestionCard() {
        let card = AppStyle.card()
        card.backgroundColor = AppStyle.paleBlue

        let title = AppStyle.label("궁금한 점이 있다면,\n언제든 물어보세요", size: 23, weight: .bold)
        let subtitle = AppStyle.label("학교생활부터 진로까지\n선배들이 답해드려요", size: 14, color: AppStyle.muted)
        let action = AppStyle.button("채팅 시작하기", primary: true) { [weak self] in
            self?.openChat()
        }
        let stack = UIStackView(arrangedSubviews: [title, subtitle, action])
        stack.axis = .vertical
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func openChat() {
        tabBarController?.selectedIndex = 1
    }

    private func openCommunity() {
        tabBarController?.selectedIndex = 2
    }

    @objc private func openNotifications() {
        let alert = UIAlertController(title: "알림", message: "새로운 알림이 없어요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
