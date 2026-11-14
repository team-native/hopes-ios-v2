import UIKit

@MainActor
extension CommunityPostDetailViewController {
    func addHeader() {
        let back = UIButton(type: .system)
        back.translatesAutoresizingMaskIntoConstraints = false
        back.setImage(UIImage(named: "community-detail-back-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        back.accessibilityLabel = "뒤로"
        back.accessibilityIdentifier = "community-post-back"
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) },
            for: .touchUpInside)
        NSLayoutConstraint.activate([
            back.widthAnchor.constraint(equalToConstant: 44),
            back.heightAnchor.constraint(equalToConstant: 44)
        ])

        let title = AppStyle.label("게시글", size: 18, weight: .medium, color: AppStyle.ink)
        let subtitle = AppStyle.label("\(post.grade) 게시판", size: 12, color: secondaryText)
        boardSubtitleLabel = subtitle
        title.heightAnchor.constraint(equalToConstant: 26).isActive = true
        subtitle.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 0
        let header = UIStackView(arrangedSubviews: [back, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    func makePostCard() -> UIView {
        let badge = makeGradeBadge(post.grade)
        gradeBadgeLabel = badge.arrangedSubviews.first as? UILabel
        let more = makeMoreButton(identifier: "community-post-actions")
        postMoreButton = more
        more.addAction(UIAction { [weak self] _ in self?.showPostActions() }, for: .touchUpInside)

        let head = UIStackView(arrangedSubviews: [badge, UIView(), more])
        head.axis = .horizontal
        head.alignment = .center

        let title = AppStyle.label(post.title, size: 16, weight: .medium)
        titleLabel = title
        let meta = AppStyle.label("\(post.grade) · \(post.time)", size: 12, color: UIColor(red: 152 / 255,
            green: 163 / 255, blue: 184 / 255, alpha: 1))
        let body = AppStyle.label(post.detailBody ?? post.body, size: 15, color: AppStyle.ink)
        body.textColor = AppStyle.ink
        bodyLabel = body

        configureLikeButton()

        let comments = commentCountButton
        comments.translatesAutoresizingMaskIntoConstraints = false
        configureCommentCountButton()
        let actions = UIStackView(arrangedSubviews: [likeButton, comments, UIView()])
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 8

        let content = UIStackView(arrangedSubviews: [head, title, meta, body, actions])
        content.axis = .vertical
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255,
            alpha: 1).withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func configureLikeButton() {
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.setImage(UIImage(named: "community-detail-heart-icon")?.withRenderingMode(.alwaysOriginal),
            for: .normal)
        likeButton.setTitle("\(likes)", for: .normal)
        likeButton.setTitleColor(AppStyle.blue, for: .normal)
        likeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        likeButton.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        likeButton.layer.cornerRadius = 17
        likeButton.accessibilityIdentifier = "community-post-like"
        likeButton.addAction(UIAction { [weak self] _ in self?.toggleLike() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            likeButton.heightAnchor.constraint(equalToConstant: 34),
            likeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])
    }

    func makeGradeBadge(_ grade: String) -> UIStackView {
        let label = AppStyle.label(grade, size: 12, color: AppStyle.blue)
        label.textAlignment = .center
        let badge = UIStackView(arrangedSubviews: [label])
        badge.axis = .horizontal
        badge.alignment = .center
        badge.isLayoutMarginsRelativeArrangement = true
        badge.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        badge.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        badge.layer.cornerRadius = 12
        return badge
    }

    func configureCommentCountButton() {
        commentCountButton.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "community-detail-comment-icon")?.withRenderingMode(.alwaysOriginal)
        commentCountButton.setImage(image, for: .normal)
        commentCountButton.setTitle("\(visibleCommentCount)", for: .normal)
        commentCountButton.setTitleColor(secondaryText, for: .normal)
        commentCountButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        commentCountButton.backgroundColor = .white
        commentCountButton.layer.cornerRadius = 17
        commentCountButton.layer.borderWidth = 1
        commentCountButton.layer.borderColor = AppStyle.line.cgColor
        commentCountButton.accessibilityIdentifier = "community-post-comment-count"
        commentCountButton.addAction(UIAction { [weak self] _ in self?.commentField.becomeFirstResponder() },
            for: .touchUpInside)
        NSLayoutConstraint.activate([
            commentCountButton.heightAnchor.constraint(equalToConstant: 34),
            commentCountButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])
    }

    func updateCommentCount() {
        commentCountLabel?.text = "댓글 \(visibleCommentCount)"
        commentCountButton.setTitle("\(visibleCommentCount)", for: .normal)
    }

    func makeMoreButton(identifier: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "community-detail-more-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = "더 보기"
        button.accessibilityIdentifier = identifier
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        return button
    }

}
