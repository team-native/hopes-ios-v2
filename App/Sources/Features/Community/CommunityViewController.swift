import UIKit

struct CommunityPost {
    let grade: String
    let title: String
    let body: String
    let time: String
    let comments: Int
    let likes: Int
    let category: String
}

@MainActor
final class CommunityViewController: AppPageViewController {
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
            self?.push(CommunitySearchViewController())
        }))
        actions.addArrangedSubview(AppStyle.button("글 작성하기", primary: true, action: { [weak self] in
            self?.push(CommunityWriteViewController())
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isViewLoaded { renderPosts() }
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
        let visiblePosts = CommunityPostStore.shared.posts.filter { selectedCategory == "전체" || $0.category == selectedCategory }
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

    private func makePostCard(_ post: CommunityPost) -> UIView {
        let card = AppStyle.card()
        let authorText = post.grade == "익명" ? "익명" : "\(post.grade) · 익명"
        let author = AppStyle.label(authorText, size: 12, weight: .medium, color: AppStyle.muted)
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
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { [weak self] _ in
            self?.push(CommunityPostDetailViewController(post: post))
        }, for: .touchUpInside)
        card.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: card.topAnchor),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(post.title), 댓글 \(post.comments)개"
        card.accessibilityTraits = .button
        return card
    }

}
