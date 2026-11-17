import UIKit

@MainActor
extension CommunityPostDetailViewController {
    func addFailedComment(text: String) -> UIStackView {
        let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        let author = AppStyle.label("10기 (나)", size: 14, weight: .medium, color: AppStyle.blue)
        author.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let status = AppStyle.label("· 전송 실패", size: 12, color: tertiary)
        let retry = UIButton(type: .custom)
        retry.setTitle("· 다시 시도", for: .normal)
        retry.setTitleColor(tertiary, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 12)
        retry.accessibilityIdentifier = "community-comment-retry"
        let more = makeMoreButton(identifier: "community-failed-comment-actions")
        more.imageView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        more.widthAnchor.constraint(equalToConstant: 24).isActive = true
        more.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let header = UIStackView(arrangedSubviews: [author, status, retry, UIView(), more])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 4

        let textLabel = AppStyle.label(text, size: 14, weight: .medium,
            color: UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1))
        textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        let card = UIStackView()
        if !commentStack.arrangedSubviews.isEmpty {
            let divider = UIView()
            divider.backgroundColor = AppStyle.line
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            card.addArrangedSubview(divider)
        }
        card.addArrangedSubview(header)
        card.addArrangedSubview(textLabel)
        card.axis = .vertical
        card.spacing = 4
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        commentStack.addArrangedSubview(card)
        retry.addAction(UIAction { [weak self, weak card] _ in
            guard let self, let card else { return }
            self.retryFailedComment(text: text, card: card)
        }, for: .touchUpInside)
        more.addAction(UIAction { [weak self, weak card] _ in
            guard let self, let card else { return }
            self.showFailedCommentActions(text: text, card: card)
        }, for: .touchUpInside)
        return card
    }

    func showFailedCommentActions(text: String, card: UIStackView) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "다시 시도", style: .default) { [weak self, weak card] _ in
            guard let self, let card else { return }
            self.retryFailedComment(text: text, card: card)
        })
        sheet.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self, weak card] _ in
            guard let self, let card else { return }
            self.commentStack.removeArrangedSubview(card)
            card.removeFromSuperview()
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(sheet, animated: true)
    }
}
