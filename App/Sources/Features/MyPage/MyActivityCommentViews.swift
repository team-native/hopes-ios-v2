import UIKit

@MainActor
extension MyActivityViewController {
    func addCommentCard(_ comment: CommunityComment) {
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
}
