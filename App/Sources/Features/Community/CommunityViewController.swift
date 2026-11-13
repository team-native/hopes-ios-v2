import UIKit

struct CommunityPost {
    let grade: String
    let title: String
    let body: String
    let detailBody: String?
    let time: String
    let comments: Int
    let likes: Int
    let category: String

    init(grade: String, title: String, body: String, time: String, comments: Int, likes: Int, category: String, detailBody: String? = nil) {
        self.grade = grade
        self.title = title
        self.body = body
        self.detailBody = detailBody
        self.time = time
        self.comments = comments
        self.likes = likes
        self.category = category
    }
}

@MainActor
final class CommunityViewController: AppPageViewController {
    private let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    private let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    private let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    private let defaultBorder = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
    private let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    private let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    private let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
    private let postStack = UIStackView()
    private var selectedBoard = "전체"
    private var boardFilters: UIStackView?
    private var publishToast: UIView?
    private var showingLoadError = ProcessInfo.processInfo.arguments.contains("--community-load-error")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addHeader()
        addBoardFilters()

        postStack.axis = .vertical
        postStack.spacing = 10
        contentStack.addArrangedSubview(postStack)
        addWriteButton()
        renderPosts()
        view.accessibilityIdentifier = "community-home-screen"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if isViewLoaded {
            renderPosts()
            if CommunityPostStore.shared.consumePublishedToast() { showPublishToast() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addHeader() {
        let title = AppStyle.label("커뮤니티", size: 28, weight: .bold, color: ink)
        title.attributedText = NSAttributedString(string: "커뮤니티", attributes: [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: ink,
            .kern: -0.4
        ])
        title.heightAnchor.constraint(equalToConstant: 38).isActive = true
        title.numberOfLines = 1
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let search = makeHeaderButton(asset: "community-search-icon", identifier: "community-search", label: "게시글 검색")
        search.addAction(UIAction { [weak self] _ in
            self?.push(CommunitySearchViewController())
        }, for: .touchUpInside)
        let profile = makeHeaderButton(asset: "community-profile-icon", identifier: "community-my-activity", label: "내 활동")
        profile.addAction(UIAction { [weak self] _ in
            self?.push(MyActivityViewController())
        }, for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [title, search, profile])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        contentStack.addArrangedSubview(header)
    }

    private func makeHeaderButton(asset: String, identifier: String, label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: asset)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = line.cgColor
        button.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).withAlphaComponent(0.05).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.accessibilityIdentifier = identifier
        button.accessibilityLabel = label
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }

    private func addBoardFilters() {
        let filters = UIStackView()
        filters.axis = .horizontal
        filters.alignment = .center
        filters.spacing = 8
        ["전체", "8기", "9기", "10기", "11기"].forEach { board in
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            var configuration = UIButton.Configuration.plain()
            configuration.title = board
            configuration.baseForegroundColor = secondary
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 14, weight: .medium)
                return outgoing
            }
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            button.configuration = configuration
            button.layer.cornerRadius = 20
            button.layer.borderWidth = 1
            button.accessibilityIdentifier = "community-board-\(board)"
            button.addAction(UIAction { [weak self] _ in self?.selectBoard(board) }, for: .touchUpInside)
            filters.addArrangedSubview(button)
        }
        filters.addArrangedSubview(UIView())
        boardFilters = filters
        contentStack.addArrangedSubview(filters)
        selectFilterAppearance()
    }

    private func addWriteButton() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "community-write-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = brandBlue
        button.layer.cornerRadius = 28
        button.layer.shadowColor = brandBlue.withAlphaComponent(0.28).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.accessibilityIdentifier = "community-write-post"
        button.accessibilityLabel = "글 작성하기"
        button.addAction(UIAction { [weak self] _ in
            self?.push(CommunityWriteViewController())
        }, for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 56),
            button.heightAnchor.constraint(equalToConstant: 56),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
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

    private func selectBoard(_ board: String) {
        selectedBoard = board
        selectFilterAppearance()
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
        let visiblePosts = CommunityPostStore.shared.posts.filter { selectedBoard == "전체" || $0.grade == selectedBoard }
        if visiblePosts.isEmpty {
            postStack.addArrangedSubview(makeEmptyState())
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
        guard let filters = boardFilters else { return }
        filters.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
            let selected = button.accessibilityIdentifier == "community-board-\(selectedBoard)"
            button.backgroundColor = selected ? softBlue : .white
            button.layer.borderColor = selected ? UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor : defaultBorder.cgColor
            var configuration = button.configuration
            configuration?.baseForegroundColor = selected ? brandBlue : secondary
            button.configuration = configuration
        }
    }

    private func makePostCard(_ post: CommunityPost) -> UIView {
        let badge = UIView()
        badge.backgroundColor = softBlue
        badge.layer.cornerRadius = 12
        let badgeLabel = AppStyle.label(post.grade, size: 12, color: brandBlue)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4),
            badge.heightAnchor.constraint(equalToConstant: 24),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 39)
        ])

        let head = UIStackView(arrangedSubviews: [badge, UIView()])
        head.axis = .horizontal
        head.alignment = .center

        let title = AppStyle.label(post.title, size: 15, weight: .medium, color: ink)
        title.attributedText = NSAttributedString(string: post.title, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: ink,
            .kern: -0.1
        ])
        let body = AppStyle.label(post.body, size: 14, weight: .medium, color: secondary)
        body.numberOfLines = 2
        let footer = UIStackView(arrangedSubviews: [
            AppStyle.label("\(post.grade) · \(post.time)", size: 12, color: tertiary),
            UIView(),
            makeStat(icon: "community-heart-icon", count: post.likes, identifier: "community-like-count"),
            makeStat(icon: "community-comment-icon", count: post.comments, identifier: "community-comment-count")
        ])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 8

        let stack = UIStackView(arrangedSubviews: [head, title, body, footer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
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

    private func makeStat(icon: String, count: Int, identifier: String) -> UIStackView {
        let image = UIImageView(image: UIImage(named: icon)?.withRenderingMode(.alwaysOriginal))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 14),
            image.heightAnchor.constraint(equalToConstant: 14)
        ])
        let value = AppStyle.label("\(count)", size: 12, color: tertiary)
        let stat = UIStackView(arrangedSubviews: [image, value])
        stat.axis = .horizontal
        stat.alignment = .center
        stat.spacing = 4
        stat.accessibilityIdentifier = identifier
        return stat
    }

    private func makeEmptyState() -> UIView {
        let label = AppStyle.label("아직 게시글이 없어요", size: 15, color: secondary)
        label.textAlignment = .center
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 150).isActive = true
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

}
