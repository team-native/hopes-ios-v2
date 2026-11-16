import UIKit

enum ChatAttachmentValidationState: Equatable, Sendable {
    case supported
    case unsupportedFormat
    case unreadablePDF
}

struct ChatAttachmentItem: Identifiable {
    let id = UUID()
    let fileName: String
    let image: UIImage?
    let url: URL?
    let validationState: ChatAttachmentValidationState
    let pageCount: Int?

    var isSupported: Bool {
        image != nil || (url != nil && validationState == .supported)
    }

    init(
        fileName: String,
        image: UIImage?,
        url: URL? = nil,
        validationState: ChatAttachmentValidationState = .supported,
        pageCount: Int? = nil
    ) {
        self.fileName = fileName
        self.image = image
        self.url = url
        self.validationState = validationState
        self.pageCount = pageCount
    }
}

@MainActor
final class ChatAttachmentTrayView: UIView {
    var onRemove: ((UUID) -> Void)?
    var onSend: ((String) -> Void)?
    var onPreferredHeightChange: ((CGFloat) -> Void)?
    var attachments: [ChatAttachmentItem] = [] {
        didSet { updateAttachments() }
    }

    private let countLabel = AppStyle.label("첨부 0개", size: 14, weight: .medium, color: ChatDetailPalette.muted)
    private let attachmentsStack = UIStackView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let unsupportedFormatBanner = UIStackView()
    private let bannerMessageLabel = AppStyle.label(
        "", size: 12, color: UIColor(red: 0.937, green: 0.267, blue: 0.345, alpha: 1)
    )
    private weak var attachmentsScrollView: UIScrollView?
    private var documentCardWidthConstraints: [NSLayoutConstraint] = []
    private var homeIndicatorSpacerHeightConstraint: NSLayoutConstraint?
    private var preferredTrayHeight: CGFloat = 225
    private var isKeyboardVisible = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureLayout() {
        configureAppearance()
        let attachmentsScroll = makeAttachmentsScrollView()
        attachmentsScrollView = attachmentsScroll
        let inputRow = makeQuestionInputRow()
        configureUnsupportedFormatBanner()
        let homeIndicatorSpacer = UIView()
        let spacerHeightConstraint = homeIndicatorSpacer.heightAnchor.constraint(equalToConstant: 21)
        spacerHeightConstraint.isActive = true
        homeIndicatorSpacerHeightConstraint = spacerHeightConstraint
        let content = UIStackView(arrangedSubviews: [
            unsupportedFormatBanner, countLabel, attachmentsScroll, inputRow, homeIndicatorSpacer
        ])
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
        layer.borderColor = ChatDetailPalette.border.cgColor
        layer.shadowColor = ChatDetailPalette.shadow.cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
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
        inputField.textColor = ChatDetailPalette.ink
        inputField.borderStyle = .none
        inputField.returnKeyType = .send
        inputField.accessibilityLabel = "첨부 자료에 대한 질문"

        let inputContainer = UIView()
        inputContainer.backgroundColor = ChatDetailPalette.canvas
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = ChatDetailPalette.border.cgColor
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
        let send = sendButton
        send.backgroundColor = ChatDetailPalette.brand
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
        let unreadablePDF = attachments.contains { $0.validationState == .unreadablePDF }
        let hasUnsupportedAttachment = attachments.contains { !$0.isSupported }
        let hasInvalidAttachment = unreadablePDF || hasUnsupportedAttachment
        unsupportedFormatBanner.isHidden = !hasInvalidAttachment
        bannerMessageLabel.text = unreadablePDF
            ? "이 PDF는 열 수 없어요. 암호를 풀거나 다른 파일로 다시 첨부해 주세요."
            : "이미지와 PDF만 첨부할 수 있어요."
        bannerMessageLabel.textColor = UIColor(red: 0.937, green: 0.267, blue: 0.345, alpha: 1)
        sendButton.isEnabled = !hasInvalidAttachment
        sendButton.backgroundColor = hasInvalidAttachment
            ? ChatDetailPalette.brand.withAlphaComponent(0.4)
            : ChatDetailPalette.brand
        preferredTrayHeight = unreadablePDF ? 293 : (hasUnsupportedAttachment ? 279 : 225)
        updatePreferredHeight()
        NSLayoutConstraint.deactivate(documentCardWidthConstraints)
        documentCardWidthConstraints.removeAll()
        attachmentsStack.arrangedSubviews.forEach { view in
            attachmentsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        attachments.forEach { attachment in
            attachmentsStack.addArrangedSubview(makeAttachmentCard(attachment))
        }
        setNeedsLayout()
    }

    func setKeyboardVisible(_ visible: Bool) {
        guard isKeyboardVisible != visible else { return }
        isKeyboardVisible = visible
        homeIndicatorSpacerHeightConstraint?.constant = visible ? 0 : 21
        updatePreferredHeight()
    }

    private func updatePreferredHeight() {
        onPreferredHeightChange?(preferredTrayHeight - (isKeyboardVisible ? 21 : 0))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateDocumentCardWidths()
    }

    private func makeAttachmentCard(_ attachment: ChatAttachmentItem) -> UIView {
        if let image = attachment.image {
            return makeImageCard(image, id: attachment.id)
        }
        let documentCard = ChatAttachmentDocumentCardFactory.make(attachment) { [weak self] id in
            self?.onRemove?(id)
        }
        documentCardWidthConstraints.append(documentCard.widthConstraint)
        return documentCard.view
    }

}

@MainActor
private extension ChatAttachmentTrayView {
    func makeImageCard(_ image: UIImage, id: UUID) -> UIView {
        let card = UIView()
        card.backgroundColor = ChatDetailPalette.brandSoft
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = ChatDetailPalette.border.cgColor
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

    func configureUnsupportedFormatBanner() {
        unsupportedFormatBanner.axis = .horizontal
        unsupportedFormatBanner.alignment = .center
        unsupportedFormatBanner.spacing = 8
        unsupportedFormatBanner.isLayoutMarginsRelativeArrangement = true
        unsupportedFormatBanner.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12, leading: 16, bottom: 12, trailing: 16
        )
        unsupportedFormatBanner.backgroundColor = UIColor(red: 1, green: 0.945, blue: 0.949, alpha: 1)
        unsupportedFormatBanner.layer.cornerRadius = 14

        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        icon.tintColor = UIColor(red: 0.937, green: 0.267, blue: 0.345, alpha: 1)
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        unsupportedFormatBanner.addArrangedSubview(icon)
        unsupportedFormatBanner.addArrangedSubview(bannerMessageLabel)
        unsupportedFormatBanner.isHidden = true
    }

    func updateDocumentCardWidths() {
        guard !documentCardWidthConstraints.isEmpty,
              let attachmentsScrollView,
              attachmentsScrollView.bounds.width > 0 else { return }
        let imageCount = attachments.filter { $0.image != nil }.count
        let documentCount = documentCardWidthConstraints.count
        let spacing = CGFloat(max(0, attachments.count - 1)) * 12
        let imageWidth = CGFloat(imageCount) * 72
        let remainingWidth = attachmentsScrollView.bounds.width - imageWidth - spacing
        let documentWidth = max(192, remainingWidth / CGFloat(documentCount))
        documentCardWidthConstraints.forEach { constraint in
            if abs(constraint.constant - documentWidth) > 0.5 {
                constraint.constant = documentWidth
            }
        }
    }

    func addRemoveButton(to card: UIView, id: UUID) {
        let hitArea = UIView()
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hitArea)
        let remove = UIButton(type: .system)
        remove.backgroundColor = ChatDetailPalette.ink
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

}

@MainActor
private extension ChatAttachmentTrayView {
    func sendQuestion() {
        guard !attachments.contains(where: { !$0.isSupported }) else { return }
        let question = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !question.isEmpty else { return }
        onSend?(question)
        inputField.text = "이 자료 요약해줘"
    }
}
