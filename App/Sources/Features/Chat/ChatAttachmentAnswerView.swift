import UIKit

@MainActor
extension ChatConversationViewController {
    func addAttachmentFormattedAnswer(sourceFileName: String) {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let source = makeAttachmentAnswerSource(fileName: sourceFileName)
        let title = AppStyle.label("외출 규정 요약", size: 18, weight: .medium, color: ChatDetailPalette.ink)
        applyAttachmentAnswerLineHeight(title, lineHeight: 26)
        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 4
        [
            "평일 외출은 사감 선생님 승인 후 가능해요.",
            "주말 외출은 금요일까지 신청해야 해요.",
            "복귀 시간은 일요일 저녁 9시예요."
        ].forEach { list.addArrangedSubview(makeAttachmentAnswerBullet($0)) }

        let content = UIStackView(arrangedSubviews: [source, title, list])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
    }

    private func makeAttachmentAnswerSource(fileName: String) -> UIStackView {
        let icon = UIImageView(image: UIImage(named: "chat-question-file-icon"))
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 12).isActive = true
        let label = AppStyle.label("\(fileName) · 첨부 자료", size: 12, color: AppStyle.blue)
        let source = UIStackView(arrangedSubviews: [icon, label])
        source.axis = .horizontal
        source.alignment = .center
        source.spacing = 6
        source.isLayoutMarginsRelativeArrangement = true
        source.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        source.backgroundColor = AppStyle.paleBlue
        source.layer.cornerRadius = 16
        source.widthAnchor.constraint(lessThanOrEqualTo: messagesStack.widthAnchor).isActive = true
        return source
    }

    private func makeAttachmentAnswerBullet(_ text: String) -> UIStackView {
        let bullet = AppStyle.label("•", size: 15, weight: .medium, color: AppStyle.blue)
        bullet.widthAnchor.constraint(equalToConstant: 10).isActive = true
        applyAttachmentAnswerLineHeight(bullet, lineHeight: 24)
        let body = AppStyle.label(text, size: 15, color: ChatDetailPalette.ink)
        body.numberOfLines = 0
        applyAttachmentAnswerLineHeight(body, lineHeight: 24)
        let row = UIStackView(arrangedSubviews: [bullet, body])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        return row
    }

    private func applyAttachmentAnswerLineHeight(_ label: UILabel, lineHeight: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        label.attributedText = NSAttributedString(string: label.text ?? "", attributes: [
            .font: label.font as Any,
            .foregroundColor: label.textColor as Any,
            .paragraphStyle: style
        ])
    }
}
