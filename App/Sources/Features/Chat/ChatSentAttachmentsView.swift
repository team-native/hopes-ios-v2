import UIKit

@MainActor
extension ChatConversationViewController {
    func addSentAttachments(_ attachments: [ChatAttachmentItem]) {
        attachmentResponseState.thumbnails.removeAll()
        attachmentResponseState.uploadProgressViews.removeAll()
        attachmentResponseState.uploadStatusLabels.removeAll()
        attachmentResponseState.uploadRetryButtons.removeAll()

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.distribution = .equalSpacing
        attachments.forEach { row.addArrangedSubview(makeSentAttachmentCell($0)) }

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

    private func makeSentAttachmentCell(_ attachment: ChatAttachmentItem) -> UIView {
        let key = attachment.id.uuidString
        let visual: UIView
        if let image = attachment.image {
            let thumbnail = makeSentImageThumbnail(image)
            attachmentResponseState.thumbnails.append(thumbnail)
            visual = thumbnail
        } else {
            visual = makeSentPDFChip(attachment.fileName)
        }

        let cell = UIStackView()
        cell.axis = .vertical
        cell.alignment = attachment.image == nil ? .leading : .center
        cell.spacing = 3
        cell.addArrangedSubview(visual)

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = AppStyle.blue
        progress.trackTintColor = AppStyle.line
        progress.accessibilityIdentifier = "chat-attachment-upload-progress-\(key)"
        cell.addArrangedSubview(progress)
        progress.widthAnchor.constraint(equalTo: visual.widthAnchor).isActive = true
        progress.heightAnchor.constraint(equalToConstant: 2).isActive = true

        let status = AppStyle.label("업로드 대기 중", size: 10, color: AppStyle.muted)
        status.textAlignment = .center
        status.accessibilityIdentifier = "chat-attachment-upload-status-\(key)"
        cell.addArrangedSubview(status)
        status.widthAnchor.constraint(equalTo: visual.widthAnchor).isActive = true

        let retry = UIButton(type: .system)
        retry.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retry.tintColor = .white
        retry.backgroundColor = AppStyle.blue
        retry.layer.cornerRadius = 16
        retry.accessibilityLabel = "\(attachment.fileName) 업로드 다시 시도"
        retry.accessibilityIdentifier = "chat-attachment-upload-retry-\(key)"
        retry.isHidden = true
        retry.addAction(UIAction { [weak self] _ in self?.retryAttachmentAnalysis() }, for: .touchUpInside)
        retry.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(retry)
        NSLayoutConstraint.activate([
            retry.centerXAnchor.constraint(equalTo: visual.centerXAnchor),
            retry.centerYAnchor.constraint(equalTo: visual.centerYAnchor),
            retry.widthAnchor.constraint(equalToConstant: 32),
            retry.heightAnchor.constraint(equalToConstant: 32)
        ])

        attachmentResponseState.uploadProgressViews[key] = progress
        attachmentResponseState.uploadStatusLabels[key] = status
        attachmentResponseState.uploadRetryButtons[key] = retry
        return cell
    }

    private func makeSentImageThumbnail(_ image: UIImage) -> UIImageView {
        let thumb = UIImageView(image: image)
        thumb.isUserInteractionEnabled = true
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

    func updateAttachmentUploadProgress(clientRequestId: String, sent: Int64, expected: Int64) {
        let value = expected > 0 ? Float(sent) / Float(expected) : 0
        attachmentResponseState.uploadProgressViews[clientRequestId]?.setProgress(value, animated: true)
        attachmentResponseState.uploadStatusLabels[clientRequestId]?.text =
            "업로드 중 · \(Int((value * 100).rounded()))%"
        attachmentResponseState.uploadRetryButtons[clientRequestId]?.isHidden = true
    }

    func updateAttachmentUploadCompleted(clientRequestId: String) {
        attachmentResponseState.uploadProgressViews[clientRequestId]?.setProgress(1, animated: true)
        attachmentResponseState.uploadStatusLabels[clientRequestId]?.text = "업로드 완료"
        attachmentResponseState.uploadRetryButtons[clientRequestId]?.isHidden = true
    }

    func updateAttachmentUploadFailed(clientRequestId: String) {
        attachmentResponseState.uploadStatusLabels[clientRequestId]?.text = "업로드 실패 · 다시 시도"
        attachmentResponseState.uploadStatusLabels[clientRequestId]?.textColor = .systemRed
        attachmentResponseState.uploadRetryButtons[clientRequestId]?.isHidden = false
    }

    func clearAttachmentUploadState() {
        attachmentResponseState.uploadedAttachmentIDs.removeAll()
        attachmentResponseState.uploadProgressViews.removeAll()
        attachmentResponseState.uploadStatusLabels.removeAll()
        attachmentResponseState.uploadRetryButtons.removeAll()
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
