import UIKit

@MainActor
extension ChatConversationViewController {
    func addSentAttachments(_ attachments: [ChatAttachmentItem]) {
        attachmentResponseState.thumbnails.removeAll()
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.distribution = .equalSpacing

        for attachment in attachments {
            if let image = attachment.image {
                let thumbnail = makeSentImageThumbnail(image)
                attachmentResponseState.thumbnails.append(thumbnail)
                row.addArrangedSubview(thumbnail)
            } else {
                row.addArrangedSubview(makeSentPDFChip(attachment.fileName))
            }
        }

        let wrapper = UIView()
        wrapper.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: wrapper.topAnchor),
            row.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            row.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor)
        ])
        messagesStack.addArrangedSubview(wrapper)
    }

    private func makeSentImageThumbnail(_ image: UIImage) -> UIImageView {
        let thumb = UIImageView(image: image)
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 16
        thumb.layer.borderWidth = 1
        thumb.layer.borderColor = AppStyle.line.cgColor
        thumb.widthAnchor.constraint(equalToConstant: 64).isActive = true
        thumb.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return thumb
    }

    private func makeSentPDFChip(_ fileName: String) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: "doc.text"))
        icon.tintColor = AppStyle.blue
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let title = AppStyle.label(fileName, size: 14, weight: .medium)
        title.lineBreakMode = .byTruncatingMiddle
        let chip = UIStackView(arrangedSubviews: [icon, title])
        chip.axis = .horizontal
        chip.alignment = .center
        chip.spacing = 8
        chip.isLayoutMarginsRelativeArrangement = true
        chip.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        chip.backgroundColor = .white
        chip.layer.cornerRadius = 16
        chip.layer.borderWidth = 1
        chip.layer.borderColor = AppStyle.line.cgColor
        chip.layer.shadowColor = UIColor(
            red: 26 / 255.0,
            green: 64 / 255.0,
            blue: 128 / 255.0,
            alpha: 0.05
        ).cgColor
        chip.layer.shadowOpacity = 1
        chip.layer.shadowRadius = 8
        chip.layer.shadowOffset = CGSize(width: 0, height: 4)
        return chip
    }

    func resizeSentAttachmentThumbnails(to size: CGFloat) {
        for thumbnail in attachmentResponseState.thumbnails {
            thumbnail.constraints
                .filter { $0.firstAttribute == .width || $0.firstAttribute == .height }
                .forEach { $0.constant = size }
        }
        view.layoutIfNeeded()
    }
}
