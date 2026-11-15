import UIKit

@MainActor
enum ChatAttachmentDocumentCardFactory {
    static func make(
        _ attachment: ChatAttachmentItem,
        onRemove: @escaping (UUID) -> Void
    ) -> (view: UIView, widthConstraint: NSLayoutConstraint) {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 72).isActive = true
        let widthConstraint = card.widthAnchor.constraint(equalToConstant: 192)
        widthConstraint.isActive = true

        let content = makeContent(attachment)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        addRemoveButton(to: card, id: attachment.id, action: onRemove)
        return (card, widthConstraint)
    }

    private static func makeContent(_ attachment: ChatAttachmentItem) -> UIStackView {
        let iconChip = UIView()
        iconChip.backgroundColor = attachment.isSupported ? AppStyle.paleBlue : .white
        iconChip.layer.cornerRadius = 12
        iconChip.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "doc.text"))
        icon.tintColor = attachment.validationState == .unreadablePDF ? dangerColor : AppStyle.blue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconChip.addSubview(icon)
        NSLayoutConstraint.activate([
            iconChip.widthAnchor.constraint(equalToConstant: 32),
            iconChip.heightAnchor.constraint(equalToConstant: 32),
            icon.centerXAnchor.constraint(equalTo: iconChip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconChip.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16)
        ])

        let name = AppStyle.label(attachment.fileName, size: 14, weight: .medium, color: AppStyle.ink)
        name.lineBreakMode = .byTruncatingMiddle
        let detail = makeDetailLabel(for: attachment.validationState)
        let labels = UIStackView(arrangedSubviews: [name, detail])
        labels.axis = .vertical
        labels.spacing = 2

        let content = UIStackView(arrangedSubviews: [iconChip, labels])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 37)
        return content
    }

    private static func makeDetailLabel(for state: ChatAttachmentValidationState) -> UILabel {
        let text: String
        let color: UIColor
        switch state {
        case .supported:
            text = "PDF 문서"
            color = AppStyle.muted
        case .unsupportedFormat:
            text = "지원하지 않는 형식"
            color = dangerColor
        case .unreadablePDF:
            text = "암호가 걸렸거나 손상된 파일"
            color = dangerColor
        }
        return AppStyle.label(text, size: 12, color: color)
    }

    private static func addRemoveButton(
        to card: UIView,
        id: UUID,
        action: @escaping (UUID) -> Void
    ) {
        let hitArea = UIView()
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hitArea)
        let remove = UIButton(type: .system)
        remove.setImage(UIImage(systemName: "xmark"), for: .normal)
        remove.tintColor = AppStyle.muted
        remove.accessibilityLabel = "첨부 제거"
        remove.addAction(UIAction { _ in action(id) }, for: .touchUpInside)
        remove.translatesAutoresizingMaskIntoConstraints = false
        hitArea.addSubview(remove)
        NSLayoutConstraint.activate([
            hitArea.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            hitArea.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 1),
            hitArea.widthAnchor.constraint(equalToConstant: 44),
            hitArea.heightAnchor.constraint(equalToConstant: 44),
            remove.centerXAnchor.constraint(equalTo: hitArea.centerXAnchor),
            remove.centerYAnchor.constraint(equalTo: hitArea.centerYAnchor),
            remove.widthAnchor.constraint(equalToConstant: 16),
            remove.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private static let dangerColor = UIColor(red: 0.937, green: 0.267, blue: 0.345, alpha: 1)
}
