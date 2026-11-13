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
    private var publishToast: UIView?
    private var showingLoadError = ProcessInfo.processInfo.arguments.contains("--community-load-error")

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
        if isViewLoaded {
            renderPosts()
            if CommunityPostStore.shared.consumePublishedToast() { showPublishToast() }
        }
    }

    private func showPublishToast() {
        publishToast?.removeFromSuperview()

        let checkCircle = UIView()
        checkCircle.backgroundColor = AppStyle.blue
        checkCircle.layer.cornerRadius = 11
        checkCircle.widthAnchor.constraint(equalToConstant: 22).isActive = true
        checkCircle.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkCircle.addSubview(checkmark)
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 12),
            checkmark.heightAnchor.constraint(equalToConstant: 12)
        ])

        let message = AppStyle.label("게시글을 등록했어요", size: 14, color: .white)
        let toast = UIStackView(arrangedSubviews: [checkCircle, message])
        toast.axis = .horizontal
        toast.alignment = .center
        toast.spacing = 10
        toast.isLayoutMarginsRelativeArrangement = true
        toast.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        toast.backgroundColor = AppStyle.ink
        toast.layer.cornerRadius = 26
        toast.layer.shadowColor = UIColor.black.cgColor
        toast.layer.shadowOpacity = 0.18
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 5)
        toast.isUserInteractionEnabled = false
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        publishToast = toast
        toast.alpha = 0
        toast.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.2) {
            toast.alpha = 1
            toast.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self, weak toast] in
            guard let self, let toast, self.publishToast === toast else { return }
            UIView.animate(withDuration: 0.2, animations: {
                toast.alpha = 0
                toast.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }, completion: { _ in
                toast.removeFromSuperview()
                self.publishToast = nil
            })
        }
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
        if showingLoadError {
            postStack.addArrangedSubview(makeLoadErrorState())
            selectFilterAppearance()
            return
        }
        let visiblePosts = CommunityPostStore.shared.posts.filter { selectedCategory == "전체" || $0.category == selectedCategory }
        if visiblePosts.isEmpty {
            postStack.addArrangedSubview(AppStyle.label("아직 게시글이 없어요", size: 15, color: AppStyle.muted))
        } else {
            visiblePosts.forEach { post in postStack.addArrangedSubview(makePostCard(post)) }
        }
        selectFilterAppearance()
    }

    func showLoadError() {
        showingLoadError = true
        renderPosts()
    }

    private func makeLoadErrorState() -> UIView {
        let illustration = UIView()
        illustration.backgroundColor = .white
        illustration.layer.cornerRadius = 44
        illustration.layer.borderWidth = 1
        illustration.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        illustration.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        illustration.layer.shadowOpacity = 0.09
        illustration.layer.shadowOffset = CGSize(width: 0, height: 8)
        illustration.layer.shadowRadius = 14
        illustration.widthAnchor.constraint(equalToConstant: 88).isActive = true
        illustration.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let assetPath = Bundle.main.path(forResource: "community-load-alert", ofType: "png")
        let icon = UIImageView(image: assetPath.flatMap(UIImage.init(contentsOfFile:)))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28)
        ])

        let title = AppStyle.label("게시글을 불러오지 못했어요", size: 18, weight: .medium)
        title.textAlignment = .center
        let subtitle = AppStyle.label("네트워크 상태를 확인한 뒤 다시 시도해 주세요.", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center
        let retryButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "다시 시도"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        retryButton.configuration = configuration
        retryButton.layer.cornerRadius = 10
        retryButton.clipsToBounds = true
        retryButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.showingLoadError = false
            self.renderPosts()
        }, for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [illustration, title, subtitle, retryButton])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12

        let container = UIView()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.72),
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            content.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        return container
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
