import UIKit

struct ChatAttachmentItem: Identifiable {
    let id = UUID()
    let fileName: String
    let image: UIImage?
    let url: URL?

    init(fileName: String, image: UIImage?, url: URL? = nil) {
        self.fileName = fileName
        self.image = image
        self.url = url
    }
}

@MainActor
final class ChatAttachmentTrayView: UIView {
    var onRemove: ((UUID) -> Void)?
    var onSend: ((String) -> Void)?
    var attachments: [ChatAttachmentItem] = [] {
        didSet { updateAttachments() }
    }

    private let countLabel = AppStyle.label("첨부 0개", size: 14, weight: .medium, color: AppStyle.muted)
    private let attachmentsStack = UIStackView()
    private let inputField = UITextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureLayout() {
        configureAppearance()
        let attachmentsScroll = makeAttachmentsScrollView()
        let inputRow = makeQuestionInputRow()
        let homeIndicatorSpacer = UIView()
        homeIndicatorSpacer.heightAnchor.constraint(equalToConstant: 21).isActive = true
        let content = UIStackView(arrangedSubviews: [countLabel, attachmentsScroll, inputRow, homeIndicatorSpacer])
        content.axis = .vertical
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 21, bottom: 0, trailing: 21)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureAppearance() {
        backgroundColor = .white
        layer.cornerRadius = 28
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.borderWidth = 1
        layer.borderColor = AppStyle.line.cgColor
        layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.09).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    private func makeAttachmentsScrollView() -> UIScrollView {
        let attachmentsScroll = UIScrollView()
        attachmentsScroll.showsHorizontalScrollIndicator = false
        attachmentsStack.axis = .horizontal
        attachmentsStack.alignment = .center
        attachmentsStack.spacing = 12
        attachmentsStack.translatesAutoresizingMaskIntoConstraints = false
        attachmentsScroll.addSubview(attachmentsStack)
        NSLayoutConstraint.activate([
            attachmentsStack.topAnchor.constraint(equalTo: attachmentsScroll.contentLayoutGuide.topAnchor, constant: 6),
            attachmentsStack.leadingAnchor.constraint(equalTo: attachmentsScroll.contentLayoutGuide.leadingAnchor),
            attachmentsStack.trailingAnchor.constraint(equalTo: attachmentsScroll.contentLayoutGuide.trailingAnchor),
            attachmentsStack.bottomAnchor.constraint(equalTo: attachmentsScroll.contentLayoutGuide.bottomAnchor),
            attachmentsStack.heightAnchor.constraint(
                equalTo: attachmentsScroll.frameLayoutGuide.heightAnchor,
                constant: -6
            )
        ])
        attachmentsScroll.heightAnchor.constraint(equalToConstant: 78).isActive = true
        return attachmentsScroll
    }

    private func makeQuestionInputRow() -> UIStackView {
        let inputContainer = makeInputContainer()
        let send = makeSendButton()
        let inputRow = UIStackView(arrangedSubviews: [inputContainer, send])
        inputRow.axis = .horizontal
        inputRow.alignment = .center
        inputRow.spacing = 8
        return inputRow
    }

    private func makeInputContainer() -> UIView {
        inputField.text = "이 자료 요약해줘"
        inputField.font = .systemFont(ofSize: 15)
        inputField.textColor = AppStyle.ink
        inputField.borderStyle = .none
        inputField.returnKeyType = .send
        inputField.accessibilityLabel = "첨부 자료에 대한 질문"

        let inputContainer = UIView()
        inputContainer.backgroundColor = AppStyle.canvas
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = AppStyle.line.cgColor
        inputContainer.heightAnchor.constraint(equalToConstant: 52).isActive = true
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputField)
        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 18),
            inputField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            inputField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 12),
            inputField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -12)
        ])
        return inputContainer
    }

    private func makeSendButton() -> UIButton {
        let send = UIButton(type: .system)
        send.backgroundColor = AppStyle.blue
        send.layer.cornerRadius = 24
        send.setImage(UIImage(named: "chat-send-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        send.imageView?.contentMode = .scaleAspectFit
        send.accessibilityLabel = "첨부 자료 질문 보내기"
        send.accessibilityIdentifier = "chat-attachment-send"
        send.addAction(UIAction { [weak self] _ in self?.sendQuestion() }, for: .touchUpInside)
        send.widthAnchor.constraint(equalToConstant: 48).isActive = true
        send.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return send
    }

    private func updateAttachments() {
        countLabel.text = "첨부 \(attachments.count)개"
        attachmentsStack.arrangedSubviews.forEach { view in
            attachmentsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        attachments.forEach { attachment in
            attachmentsStack.addArrangedSubview(makeAttachmentCard(attachment))
        }
    }

    private func makeAttachmentCard(_ attachment: ChatAttachmentItem) -> UIView {
        if let image = attachment.image {
            return makeImageCard(image, id: attachment.id)
        }
        return makePDFCard(attachment)
    }

    private func makeImageCard(_ image: UIImage, id: UUID) -> UIView {
        let card = UIView()
        card.backgroundColor = AppStyle.paleBlue
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        let preview = UIImageView(image: image)
        preview.contentMode = .scaleAspectFill
        preview.clipsToBounds = true
        preview.layer.cornerRadius = 16
        preview.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(preview)
        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalToConstant: 72),
            card.heightAnchor.constraint(equalToConstant: 72),
            preview.topAnchor.constraint(equalTo: card.topAnchor),
            preview.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            preview.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            preview.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        addRemoveButton(to: card, id: id)
        return card
    }

    private func makePDFCard(_ attachment: ChatAttachmentItem) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: 192).isActive = true
        card.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let iconChip = UIView()
        iconChip.backgroundColor = AppStyle.paleBlue
        iconChip.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(systemName: "doc.text"))
        icon.tintColor = AppStyle.blue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconChip.translatesAutoresizingMaskIntoConstraints = false
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
        let type = AppStyle.label("PDF 문서", size: 12, color: AppStyle.muted)
        let labels = UIStackView(arrangedSubviews: [name, type])
        labels.axis = .vertical
        labels.spacing = 2
        let content = UIStackView(arrangedSubviews: [iconChip, labels])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        addPDFRemoveButton(to: card, id: attachment.id)
        return card
    }

    private func addRemoveButton(to card: UIView, id: UUID) {
        let hitArea = UIView()
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hitArea)
        let remove = UIButton(type: .system)
        remove.backgroundColor = AppStyle.ink
        remove.layer.cornerRadius = 10
        remove.setImage(UIImage(systemName: "xmark"), for: .normal)
        remove.tintColor = .white
        remove.accessibilityLabel = "첨부 제거"
        remove.addAction(UIAction { [weak self] _ in self?.onRemove?(id) }, for: .touchUpInside)
        remove.translatesAutoresizingMaskIntoConstraints = false
        hitArea.addSubview(remove)
        NSLayoutConstraint.activate([
            hitArea.topAnchor.constraint(equalTo: card.topAnchor, constant: -18),
            hitArea.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 18),
            hitArea.widthAnchor.constraint(equalToConstant: 44),
            hitArea.heightAnchor.constraint(equalToConstant: 44),
            remove.centerXAnchor.constraint(equalTo: hitArea.centerXAnchor),
            remove.centerYAnchor.constraint(equalTo: hitArea.centerYAnchor),
            remove.widthAnchor.constraint(equalToConstant: 20),
            remove.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func addPDFRemoveButton(to card: UIView, id: UUID) {
        let hitArea = UIView()
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hitArea)
        let remove = UIButton(type: .system)
        remove.setImage(UIImage(systemName: "xmark"), for: .normal)
        remove.tintColor = AppStyle.muted
        remove.accessibilityLabel = "첨부 제거"
        remove.addAction(UIAction { [weak self] _ in self?.onRemove?(id) }, for: .touchUpInside)
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

}

@MainActor
private extension ChatAttachmentTrayView {
    func sendQuestion() {
        let question = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !question.isEmpty else { return }
        onSend?(question)
        inputField.text = "이 자료 요약해줘"
    }
}
