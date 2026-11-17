import UIKit

@MainActor
final class MyActivityViewController: AppPageViewController {
    let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
    let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    let subtleLine = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    let tabsStack = UIStackView()
    let itemsStack = UIStackView()
    var selectedTab = 0
    var previousNavigationBarHidden = false

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "내 활동"
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        previousNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 14

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
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if isViewLoaded { renderItems() }
        guard CommunityPostStore.shared.isServerBacked else { return }
        Task { [weak self] in try? await CommunityPostStore.shared.refresh(); self?.renderItems() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
    }

    private func addHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "MyActivityBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backButton.accessibilityLabel = "뒤로"
        backButton.accessibilityIdentifier = "my-activity-back"
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let titleLabel = AppStyle.label("내 활동", size: 18, weight: .medium, color: ink)
        let subtitleLabel = AppStyle.label("내가 쓴 글과 댓글은 나만 볼 수 있어요", size: 12, color: secondary)
        titleLabel.attributedText = NSAttributedString(string: "내 활동", attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: ink,
            .kern: -0.2,
            .paragraphStyle: lineStyle(height: 26)
        ])
        subtitleLabel.attributedText = NSAttributedString(string: "내가 쓴 글과 댓글은 나만 볼 수 있어요", attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: secondary,
            .paragraphStyle: lineStyle(height: 16)
        ])
        let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titles.axis = .vertical
        titles.spacing = 0

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
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
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
            button?.setTitleColor(selected ? UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255,
                alpha: 1) : secondary, for: .normal)
            button?.tintColor = selected ? UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255,
                alpha: 1) : secondary
            button?.isSelected = selected
            button?.backgroundColor = selected ? softBlue : .white
            button?.layer.borderWidth = 1
            button?.layer.borderColor = selected
                ? UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
                : UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1).cgColor
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
            posts.forEach(addPostCard)
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

}

@MainActor
extension MyActivityViewController {
    func addPostCard(_ post: CommunityPost) {
        let content = makePostContent(post)
        let card = makePostCardContainer(content: content, post: post)
        itemsStack.addArrangedSubview(card)
    }

    private func makePostContent(_ post: CommunityPost) -> UIStackView {
        let badge = makeBadge(post.grade)
        let more = UIImageView(image: UIImage(named: "my-activity-more-icon")?.withRenderingMode(.alwaysOriginal))
        more.contentMode = .scaleAspectFit
        more.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            more.widthAnchor.constraint(equalToConstant: 18),
            more.heightAnchor.constraint(equalToConstant: 18)
        ])
        let head = UIStackView(arrangedSubviews: [badge, UIView(), more])
        head.axis = .horizontal
        head.alignment = .center

        let title = AppStyle.label(post.title, size: 15, weight: .medium, color: ink)
        title.numberOfLines = 1
        title.attributedText = NSAttributedString(string: post.title, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: ink,
            .kern: -0.1,
            .paragraphStyle: lineStyle(height: 24)
        ])
        let body = AppStyle.label(post.body, size: 14, weight: .medium, color: secondary)
        body.attributedText = NSAttributedString(string: post.body, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: secondary,
            .paragraphStyle: lineStyle(height: 20)
        ])
        body.numberOfLines = 2

        let footer = UIStackView(arrangedSubviews: [
            AppStyle.label("\(post.authorCohort) · \(post.time)", size: 12, color: tertiary),
            UIView(),
            makeStat(icon: "my-activity-heart-icon", count: post.likes),
            makeStat(icon: "my-activity-chat-icon", count: post.comments)
        ])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 12

        let content = UIStackView(arrangedSubviews: [head, title, body, footer])
        content.axis = .vertical
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        return content
    }

    private func makePostCardContainer(content: UIStackView, post: CommunityPost) -> UIControl {
        let card = UIControl()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = subtleLine.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.addPassthroughSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        card.addAction(UIAction { [weak self] _ in
            self?.push(CommunityPostDetailViewController(post: post, isMine: true))
        }, for: .touchUpInside)
        card.accessibilityLabel = "\(post.title), 좋아요 \(post.likes), 댓글 \(post.comments)개"
        card.accessibilityTraits = .button
        let postIndex = CommunityPostStore.shared.myPosts.firstIndex { $0.title == post.title } ?? 0
        card.accessibilityIdentifier = "my-activity-post-\(postIndex)"
        return card
    }

    func makeBadge(_ text: String) -> UIView {
        let badge = UIView()
        badge.backgroundColor = softBlue
        badge.layer.cornerRadius = 12
        let label = AppStyle.label(text, size: 12, color: UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255,
            alpha: 1))
        label.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10),
            badge.heightAnchor.constraint(equalToConstant: 24),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 39)
        ])
        return badge
    }

    func makeStat(icon: String, count: Int) -> UIStackView {
        let image = UIImageView(image: UIImage(named: icon)?.withRenderingMode(.alwaysOriginal))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 14),
            image.heightAnchor.constraint(equalToConstant: 14)
        ])
        let label = AppStyle.label("\(count)", size: 12, color: tertiary)
        let stat = UIStackView(arrangedSubviews: [image, label])
        stat.axis = .horizontal
        stat.alignment = .center
        stat.spacing = 4
        return stat
    }

    func addPostsEmptyState() {
        let content = makePostsEmptyStateContent()
        let container = UIView()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            content.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        itemsStack.addArrangedSubview(container)
        container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, constant: -121)
            .isActive = true
    }

    private func makePostsEmptyStateContent() -> UIStackView {
        let illustration = UIView()
        illustration.backgroundColor = .white
        illustration.layer.cornerRadius = 44
        illustration.layer.borderWidth = 1
        illustration.layer.borderColor = subtleLine.cgColor
        illustration.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        illustration.layer.shadowOpacity = 0.09
        illustration.layer.shadowOffset = CGSize(width: 0, height: 8)
        illustration.layer.shadowRadius = 28
        illustration.widthAnchor.constraint(equalToConstant: 88).isActive = true
        illustration.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let pen = UIImageView(image: UIImage(named: "MyActivityEmptyPen")?.withRenderingMode(.alwaysOriginal))
        pen.contentMode = .scaleAspectFit
        pen.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(pen)
        NSLayoutConstraint.activate([
            pen.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            pen.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            pen.widthAnchor.constraint(equalToConstant: 36),
            pen.heightAnchor.constraint(equalToConstant: 36)
        ])

        let title = makePostsEmptyTitle()
        let subtitle = makePostsEmptySubtitle()
        let writeButton = makePostsEmptyWriteButton()
        let messageStack = UIStackView(arrangedSubviews: [illustration, title, subtitle, writeButton])
        messageStack.axis = .vertical
        messageStack.alignment = .center
        messageStack.spacing = 12

        return messageStack
    }

    private func makePostsEmptyTitle() -> UILabel {
        let title = AppStyle.label("아직 작성한 글이 없어요", size: 18, weight: .medium)
        title.textAlignment = .center
        title.attributedText = NSAttributedString(string: "아직 작성한 글이 없어요", attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: ink,
            .kern: -0.2,
            .paragraphStyle: lineStyle(height: 26)
        ])
        return title
    }

    private func makePostsEmptySubtitle() -> UILabel {
        let subtitle = AppStyle.label("궁금한 걸 커뮤니티에 물어보세요.", size: 14, weight: .medium, color: secondary)
        subtitle.textAlignment = .center
        subtitle.attributedText = NSAttributedString(string: "궁금한 걸 커뮤니티에 물어보세요.", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: secondary,
            .paragraphStyle: lineStyle(height: 20)
        ])
        return subtitle
    }

    private func makePostsEmptyWriteButton() -> UIButton {
        let writeButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "글쓰기"
        configuration.baseBackgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        writeButton.configuration = configuration
        writeButton.layer.cornerRadius = 10
        writeButton.clipsToBounds = true
        writeButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        writeButton.addAction(UIAction { [weak self] _ in
            self?.push(CommunityWriteViewController())
        }, for: .touchUpInside)
        return writeButton
    }
}
