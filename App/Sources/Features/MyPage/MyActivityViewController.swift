import UIKit

@MainActor
final class MyActivityViewController: AppPageViewController {
    private let tabsStack = UIStackView()
    private let itemsStack = UIStackView()
    private var selectedTab = 1
    private var previousNavigationBarHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "내 활동"
        previousNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(true, animated: false)

        addHeader()
        addTabs()

        itemsStack.axis = .vertical
        itemsStack.spacing = 12
        contentStack.addArrangedSubview(itemsStack)
        renderItems()
    }

    override func configureScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if isViewLoaded { renderItems() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
    }

    private func addHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = AppStyle.ink
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let titleLabel = AppStyle.label("내 활동", size: 18, weight: .medium)
        let subtitleLabel = AppStyle.label("내가 쓴 글과 댓글은 나만 볼 수 있어요", size: 12, color: AppStyle.muted)
        let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titles.axis = .vertical
        titles.spacing = 1

        let header = UIStackView(arrangedSubviews: [backButton, titles])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addTabs() {
        tabsStack.axis = .horizontal
        tabsStack.spacing = 8
        tabsStack.addArrangedSubview(makeTab(title: "작성글", index: 0))
        tabsStack.addArrangedSubview(makeTab(title: "댓글", index: 1))
        tabsStack.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(tabsStack)
    }

    private func makeTab(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.layer.cornerRadius = 20
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let self, let button else { return }
            self.selectedTab = button.tag
            self.updateTabs()
            self.renderItems()
        }, for: .touchUpInside)
        return button
    }

    private func updateTabs() {
        let postButton = tabsStack.arrangedSubviews.first as? UIButton
        let commentButton = tabsStack.arrangedSubviews.dropFirst().first as? UIButton
        let values = [
            (postButton, "작성글 \(CommunityPostStore.shared.myPosts.count)", selectedTab == 0),
            (commentButton, "댓글 \(CommunityPostStore.shared.myComments.count)", selectedTab == 1)
        ]

        values.forEach { value in
            let (button, title, selected) = value
            button?.setTitle(title, for: .normal)
            button?.setTitleColor(selected ? AppStyle.blue : AppStyle.muted, for: .normal)
            button?.backgroundColor = selected ? AppStyle.paleBlue : .white
            button?.layer.borderWidth = 1
            button?.layer.borderColor = selected
                ? UIColor(red: 0.66, green: 0.80, blue: 0.98, alpha: 1).cgColor
                : UIColor(red: 0.86, green: 0.90, blue: 0.96, alpha: 1).cgColor
        }
    }

    private func renderItems() {
        updateTabs()
        itemsStack.arrangedSubviews.forEach { view in
            itemsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if selectedTab == 0 {
            let posts = CommunityPostStore.shared.myPosts
            guard !posts.isEmpty else {
                addPostsEmptyState()
                return
            }
            posts.forEach { post in
                addActivityRow(post.title, subtitle: "\(post.category) · \(post.time) · 댓글 \(post.comments)", symbol: "doc.text") { [weak self] in
                    self?.push(CommunityPostDetailViewController(post: post, isMine: true))
                }
            }
            return
        }

        let comments = CommunityPostStore.shared.myComments
        guard !comments.isEmpty else {
            itemsStack.addArrangedSubview(AppStyle.label("작성한 댓글이 없어요", size: 14, color: AppStyle.muted))
            return
        }
        comments.forEach { comment in
            addCommentCard(comment)
        }
    }

    private func addPostsEmptyState() {
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

        let assetPath = Bundle.main.path(forResource: "empty-state-pen", ofType: "png")
        let pen = UIImageView(image: assetPath.flatMap(UIImage.init(contentsOfFile:)))
        pen.contentMode = .scaleAspectFit
        pen.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(pen)
        NSLayoutConstraint.activate([
            pen.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            pen.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            pen.widthAnchor.constraint(equalToConstant: 36),
            pen.heightAnchor.constraint(equalToConstant: 36)
        ])

        let title = AppStyle.label("아직 작성한 글이 없어요", size: 18, weight: .medium)
        title.textAlignment = .center
        let subtitle = AppStyle.label("궁금한 걸 커뮤니티에 물어보세요.", size: 14, weight: .medium, color: AppStyle.muted)
        subtitle.textAlignment = .center
        let writeButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "글쓰기"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        writeButton.configuration = configuration
        writeButton.layer.cornerRadius = 10
        writeButton.clipsToBounds = true
        writeButton.addAction(UIAction { [weak self] _ in
            self?.push(CommunityWriteViewController())
        }, for: .touchUpInside)

        let messageStack = UIStackView(arrangedSubviews: [illustration, title, subtitle, writeButton])
        messageStack.axis = .vertical
        messageStack.alignment = .center
        messageStack.spacing = 12

        let container = UIView()
        container.addSubview(messageStack)
        messageStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.72),
            messageStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            messageStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            messageStack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            messageStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        itemsStack.addArrangedSubview(container)
    }

    private func addCommentCard(_ comment: CommunityComment) {
        let card = UIControl()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 8

        let boardBadge = AppStyle.label(comment.board, size: 12, color: AppStyle.blue)
        boardBadge.backgroundColor = AppStyle.paleBlue
        boardBadge.textAlignment = .center
        boardBadge.layer.cornerRadius = 14
        boardBadge.clipsToBounds = true
        boardBadge.setContentHuggingPriority(.required, for: .horizontal)
        let postTitle = AppStyle.label(comment.postTitle, size: 12, color: AppStyle.muted)
        postTitle.numberOfLines = 1
        let header = UIStackView(arrangedSubviews: [boardBadge, postTitle])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        let body = AppStyle.label(comment.text, size: 15)
        let time = AppStyle.label(comment.time, size: 12, color: UIColor(red: 0.60, green: 0.65, blue: 0.73, alpha: 1))
        let content = UIStackView(arrangedSubviews: [header, body, time])
        content.axis = .vertical
        content.spacing = 6
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        card.addAction(UIAction { [weak self] _ in
            guard let post = CommunityPostStore.shared.posts.first(where: { $0.title == comment.postTitle }) else {
                self?.showMessage("원 게시글을 찾을 수 없어요")
                return
            }
            self?.push(CommunityPostDetailViewController(post: post))
        }, for: .touchUpInside)
        card.accessibilityLabel = "\(comment.board), \(comment.postTitle), \(comment.text), \(comment.time)"
        itemsStack.addArrangedSubview(card)
    }

    private func addActivityRow(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = AppStyle.line.cgColor
        var config = UIButton.Configuration.plain()
        config.title = title
        config.subtitle = subtitle
        config.image = UIImage(systemName: symbol)
        config.imagePlacement = .leading
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        config.baseForegroundColor = AppStyle.ink
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        itemsStack.addArrangedSubview(button)
    }
}
