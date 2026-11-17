import UIKit

@MainActor
extension MyActivityViewController {
    func addCommentCard(_ comment: CommunityComment) {
        let card = UIControl()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = subtleLine.cgColor
        card.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 16

        let boardBadge = makeBadge(comment.board)
        boardBadge.setContentHuggingPriority(.required, for: .horizontal)
        let postTitle = makeCommentPostTitle(comment.postTitle)
        let header = UIStackView(arrangedSubviews: [boardBadge, postTitle])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        let body = makeCommentBody(comment.text)
        let time = makeCommentTime(comment.time)
        let content = UIStackView(arrangedSubviews: [header, body, time])
        content.axis = .vertical
        content.spacing = 6
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addPassthroughSubview(content)

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

    private func makeCommentPostTitle(_ text: String) -> UILabel {
        let label = AppStyle.label(text, size: 12, color: secondary)
        label.numberOfLines = 1
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: secondary,
            .paragraphStyle: lineStyle(height: 16)
        ])
        return label
    }

    private func makeCommentBody(_ text: String) -> UILabel {
        let label = AppStyle.label(text, size: 15, color: ink)
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: ink,
            .kern: -0.1,
            .paragraphStyle: lineStyle(height: 24)
        ])
        return label
    }

    private func makeCommentTime(_ text: String) -> UILabel {
        let label = AppStyle.label(text, size: 12, color: tertiary)
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: tertiary,
            .paragraphStyle: lineStyle(height: 16)
        ])
        return label
    }

    func lineStyle(height: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = height
        style.maximumLineHeight = height
        return style
    }
}
