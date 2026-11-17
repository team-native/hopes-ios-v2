import UIKit

@MainActor
enum CommunityFormViews {
    static func privacyNotice() -> UIView {
        let lock = UIImageView(image: UIImage(named: "community-write-lock-icon")?.withRenderingMode(.alwaysOriginal))
        lock.widthAnchor.constraint(equalToConstant: 18).isActive = true
        lock.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let messageText = "작성자는 기수만 표시돼요. 이름·학번은 다른 사용자에게 공개되지 않아요."
        let message = UILabel()
        message.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 16
        paragraphStyle.maximumLineHeight = 16
        message.attributedText = NSAttributedString(string: messageText, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: AppStyle.muted,
            .paragraphStyle: paragraphStyle
        ])
        let notice = UIStackView(arrangedSubviews: [lock, message])
        notice.axis = .horizontal
        notice.alignment = .top
        notice.spacing = 8
        notice.isLayoutMarginsRelativeArrangement = true
        notice.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        notice.backgroundColor = AppStyle.paleBlue
        notice.layer.cornerRadius = 16
        notice.accessibilityIdentifier = "community-privacy-notice"
        return notice
    }

    static func flexibleSpacer() -> UIView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        spacer.setContentCompressionResistancePriority(UILayoutPriority(1), for: .vertical)
        return spacer
    }

    static func pinToBottom(_ contentStack: UIStackView, in scrollView: UIScrollView, safeArea: UILayoutGuide,
                            minimumOffset: CGFloat) -> NSLayoutConstraint {
        scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .bottom
        })?.constant = -3
        let constraint = contentStack.heightAnchor.constraint(
            greaterThanOrEqualTo: safeArea.heightAnchor, constant: -minimumOffset
        )
        constraint.isActive = true
        return constraint
    }
}
