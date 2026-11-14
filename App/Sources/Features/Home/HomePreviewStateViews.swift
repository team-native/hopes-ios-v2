import UIKit

@MainActor
enum HomePreviewStateViews {
    static func notificationButton(action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        let imageView = UIImageView(image: UIImage(named: "home-notification-icon")?.withRenderingMode(.alwaysOriginal))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: button.topAnchor, constant: -12),
            imageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: -16),
            imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 20)
        ])
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    static func sectionHeaderContainer(_ content: UIView) -> UIView {
        let container = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    static func skeletonCard(height: CGFloat) -> UIView {
        let stack = skeletonStack()
        stack.heightAnchor.constraint(equalToConstant: height).isActive = true
        return stack
    }

    static func popularSkeleton() -> UIView {
        skeletonStack()
    }

    static func tipsCard(borderColor: UIColor) -> UIView {
        let title = label("질문 잘하는 방법", size: 14, weight: .medium, color: AppStyle.muted, lineHeight: 20)
        let header = UIView()
        let headerLabel = title
        header.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            headerLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])

        let card = UIStackView(arrangedSubviews: [skeletonRow(), skeletonRow()])
        card.axis = .vertical
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = borderColor.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)

        let section = UIStackView(arrangedSubviews: [header, card])
        section.axis = .vertical
        section.spacing = 16
        return section
    }

    static func popularError(tertiary: UIColor, retry: @escaping () -> Void) -> UIView {
        let icon = UIImageView(image: UIImage(named: "home-alert-icon"))
        icon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20)
        ])
        let title = label(
            "인기글을 불러오지 못했어요",
            size: 15,
            weight: .medium,
            color: UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1),
            lineHeight: 24,
            kern: -0.1
        )
        let headline = UIStackView(arrangedSubviews: [icon, title])
        headline.axis = .horizontal
        headline.alignment = .center
        headline.spacing = 8

        let message = label(
            "잠시 후 다시 시도해 주세요. 채팅은 그대로 이용할 수 있어요.",
            size: 14,
            weight: .medium,
            color: AppStyle.muted,
            lineHeight: 20
        )
        let retryButton = UIButton(type: .system)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: tertiary,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        retryButton.setAttributedTitle(NSAttributedString(string: "다시 시도", attributes: attributes), for: .normal)
        retryButton.contentHorizontalAlignment = .leading
        retryButton.addAction(UIAction { _ in retry() }, for: .touchUpInside)

        let card = UIStackView(arrangedSubviews: [headline, message, retryButton])
        card.axis = .vertical
        card.alignment = .leading
        card.spacing = 4
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        return card
    }

    private static func skeletonStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            skeletonShape(width: 48, height: 20, radius: 10),
            skeletonShape(width: 240, height: 14, radius: 7),
            skeletonShape(width: 300, height: 12, radius: 6),
            skeletonShape(width: 200, height: 12, radius: 6)
        ])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        stack.backgroundColor = .white
        stack.layer.cornerRadius = 22
        return stack
    }

    private static func skeletonRow() -> UIView {
        let icon = skeletonShape(width: 36, height: 36, radius: 12)
        let lines = UIStackView(arrangedSubviews: [
            skeletonShape(width: 220, height: 12, radius: 6),
            skeletonShape(width: 140, height: 10, radius: 5)
        ])
        lines.axis = .vertical
        lines.alignment = .leading
        lines.spacing = 8
        let row = UIStackView(arrangedSubviews: [icon, lines])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        return row
    }

    private static func skeletonShape(width: CGFloat, height: CGFloat, radius: CGFloat) -> UIView {
        let shape = UIView()
        shape.backgroundColor = UIColor(red: 237 / 255, green: 241 / 255, blue: 247 / 255, alpha: 1)
        shape.layer.cornerRadius = radius
        NSLayoutConstraint.activate([
            shape.widthAnchor.constraint(equalToConstant: width),
            shape.heightAnchor.constraint(equalToConstant: height)
        ])
        return shape
    }

    static func label(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor,
        lineHeight: CGFloat,
        kern: CGFloat = 0
    ) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern
        ])
        return label
    }
}
