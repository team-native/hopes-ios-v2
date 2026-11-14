import UIKit

@MainActor
extension CommunityViewController {
    func makeLoadErrorState() -> UIView {
        let content = makeLoadErrorContent()
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

    private func makeLoadErrorContent() -> UIStackView {
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
        return content
    }

    func selectFilterAppearance() {
        guard let filters = boardFilters else { return }
        filters.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
            let selected = button.accessibilityIdentifier == "community-board-\(selectedBoard)"
            button.backgroundColor = selected ? softBlue : .white
            button.layer.borderColor = selected ? UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255,
                alpha: 1).cgColor : defaultBorder.cgColor
            var configuration = button.configuration
            configuration?.baseForegroundColor = selected ? brandBlue : secondary
            button.configuration = configuration
        }
    }

}

@MainActor
extension CommunityViewController {
    func makePostCard(_ post: CommunityPost) -> UIView {
        let stack = makePostCardContent(post)
        let card = makePostCardContainer(content: stack, post: post)
        return card
    }

    private func makePostCardContent(_ post: CommunityPost) -> UIStackView {
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

        let title = makeCommunityLabel(post.title, size: 15, weight: .medium, color: ink, lineHeight: 24, kern: -0.1)
        let body = makeCommunityLabel(post.body, size: 14, weight: .medium, color: secondary, lineHeight: 20)
        body.numberOfLines = 2
        let footer = UIStackView(arrangedSubviews: [
            makeCommunityLabel(
                "\(post.grade) · \(post.time)",
                size: 12,
                weight: .regular,
                color: tertiary,
                lineHeight: 16
            ),
            UIView(),
            makeStat(icon: "community-heart-icon", count: post.likes, identifier: "community-like-count"),
            makeStat(icon: "community-comment-icon", count: post.comments, identifier: "community-comment-count")
        ])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 12

        let stack = UIStackView(arrangedSubviews: [head, title, body, footer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }

    private func makeCommunityLabel(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        lineHeight: CGFloat,
        kern: CGFloat = 0
    ) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .kern: kern
        ])
        return label
    }

    private func makePostCardContainer(content stack: UIStackView, post: CommunityPost) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255,
            alpha: 1).withAlphaComponent(0.05).cgColor
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

    func makeStat(icon: String, count: Int, identifier: String) -> UIStackView {
        let image = UIImageView(image: UIImage(named: icon)?.withRenderingMode(.alwaysOriginal))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 14),
            image.heightAnchor.constraint(equalToConstant: 14)
        ])
        let value = makeCommunityLabel("\(count)", size: 12, weight: .regular, color: tertiary, lineHeight: 16)
        let stat = UIStackView(arrangedSubviews: [image, value])
        stat.axis = .horizontal
        stat.alignment = .center
        stat.spacing = 4
        stat.accessibilityIdentifier = identifier
        return stat
    }

    func makeEmptyState() -> UIView {
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
