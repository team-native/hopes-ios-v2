import UIKit

@MainActor
final class CommunityViewController: AppPageViewController {
    private struct Post {
        let grade: String
        let title: String
        let body: String
        let time: String
        let comments: Int
        let likes: Int
        let category: String
    }

    private let posts = [
        Post(grade: "10기", title: "기숙사 와이파이 다들 잘 돼?", body: "3층 끝방인데 저녁만 되면 너무 느려져서… 다른 층은 어떤지 궁금해.", time: "10분 전", comments: 12, likes: 5, category: "질문"),
        Post(grade: "10기", title: "전공 동아리 면접 후기 공유", body: "어제 보고 왔는데 생각보다 분위기 편했어. 질문은 주로 지원 동기 위주였음.", time: "1시간 전", comments: 34, likes: 9, category: "정보"),
        Post(grade: "9기", title: "취업 준비 언제부터 시작했어?", body: "2학년 여름방학부터 포트폴리오 만들기 시작했는데 늦은 건지 모르겠어.", time: "3시간 전", comments: 21, likes: 14, category: "질문")
    ]

    private let postStack = UIStackView()
    private var selectedCategory = "전체"
    private var categoryFilters: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "커뮤니티"
        addHeading("커뮤니티", subtitle: "학교생활 이야기를 나눠보세요")

        let actions = UIStackView()
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually
        actions.addArrangedSubview(AppStyle.button("검색", action: { [weak self] in
            self?.showMessage("게시글 검색은 검색 화면 이슈에서 연결할게요")
        }))
        actions.addArrangedSubview(AppStyle.button("글 작성하기", primary: true, action: { [weak self] in
            self?.showMessage("글 작성 화면은 다음 커뮤니티 화면 이슈에서 연결할게요")
        }))
        contentStack.addArrangedSubview(actions)

        let filters = UIStackView()
        filters.axis = .horizontal
        filters.spacing = 8
        ["전체", "질문", "정보"].forEach { category in
            let button = UIButton(type: .system)
            button.setTitle(category, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.addAction(UIAction { [weak self] _ in self?.selectCategory(category) }, for: .touchUpInside)
            button.accessibilityIdentifier = category
            filters.addArrangedSubview(button)
        }
        filters.addArrangedSubview(UIView())
        categoryFilters = filters
        contentStack.addArrangedSubview(filters)

        postStack.axis = .vertical
        postStack.spacing = 12
        contentStack.addArrangedSubview(postStack)
        renderPosts()
    }

    private func selectCategory(_ category: String) {
        selectedCategory = category
        if let filters = categoryFilters {
            filters.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
                let selected = button.accessibilityIdentifier == category
                button.backgroundColor = selected ? AppStyle.blue : .white
                button.setTitleColor(selected ? .white : AppStyle.ink, for: .normal)
            }
        }
        renderPosts()
    }

    private func renderPosts() {
        postStack.arrangedSubviews.forEach { view in
            postStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let visiblePosts = posts.filter { selectedCategory == "전체" || $0.category == selectedCategory }
        if visiblePosts.isEmpty {
            postStack.addArrangedSubview(AppStyle.label("아직 게시글이 없어요", size: 15, color: AppStyle.muted))
        } else {
            visiblePosts.forEach { post in postStack.addArrangedSubview(makePostCard(post)) }
        }
        selectFilterAppearance()
    }

    private func selectFilterAppearance() {
        guard let filters = categoryFilters else { return }
        filters.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
            let selected = button.accessibilityIdentifier == selectedCategory
            button.backgroundColor = selected ? AppStyle.blue : .white
            button.setTitleColor(selected ? .white : AppStyle.ink, for: .normal)
        }
    }

    private func makePostCard(_ post: Post) -> UIView {
        let card = AppStyle.card()
        let author = AppStyle.label("\(post.grade)  ·  익명", size: 12, weight: .medium, color: AppStyle.muted)
        let title = AppStyle.label(post.title, size: 16, weight: .bold)
        let body = AppStyle.label(post.body, size: 14, color: AppStyle.muted)
        body.numberOfLines = 2
        let footer = UIStackView()
        footer.axis = .horizontal
        footer.spacing = 14
        footer.addArrangedSubview(AppStyle.label("\(post.grade) · \(post.time)", size: 12, color: AppStyle.muted))
        footer.addArrangedSubview(UIView())
        footer.addArrangedSubview(AppStyle.label("♡  \(post.likes)", size: 12, color: AppStyle.muted))
        footer.addArrangedSubview(AppStyle.label("댓글  \(post.comments)", size: 12, color: AppStyle.muted))

        let stack = UIStackView(arrangedSubviews: [author, title, body, footer])
        stack.axis = .vertical
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showPostDetailNotice)))
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(post.title), 댓글 \(post.comments)개"
        card.accessibilityTraits = .button
        return card
    }

    @objc private func showPostDetailNotice() {
        showMessage("게시글 상세 화면은 별도 화면 이슈에서 연결할게요")
    }
}
