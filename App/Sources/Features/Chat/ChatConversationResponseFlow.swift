import UIKit
import Network

@MainActor
extension ChatConversationViewController {
    func observeNetworkStatus() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.updateNetworkStatus(isOffline: path.status != .satisfied) }
        }
        networkMonitor.start(queue: DispatchQueue(label: "kr.hs.gsm.hopes.chat-network"))
    }

    func updateNetworkStatus(isOffline: Bool) {
        guard self.isOffline != isOffline else { return }
        self.isOffline = isOffline
        if isOffline {
            showOfflineBanner()
            inputField.placeholder = "오프라인 상태예요"
            inputField.isEnabled = false
            messageSendButton?.isEnabled = false
            messageSendButton?.backgroundColor = LocationMapStyle.brand.withAlphaComponent(0.55)
            if generationTimer != nil {
                generationTimer?.cancel()
                generationTimer = nil
                if let pendingAnswerCard {
                    messagesStack.removeArrangedSubview(pendingAnswerCard)
                    pendingAnswerCard.removeFromSuperview()
                    self.pendingAnswerCard = nil
                }
                removePendingAttachmentAnalysisCard()
                stopAnswerButton.isHidden = true
                if attachmentResponseState.lastSentAttachments != nil {
                    showAttachmentAnalysisFailure()
                } else {
                    retryWhenOnline = true
                    showPendingStatus()
                }
            }
        } else {
            offlineBanner?.removeFromSuperview()
            offlineBanner = nil
            pendingStatusRow?.removeFromSuperview()
            pendingStatusRow = nil
            inputField.placeholder = "추가 질문 입력…"
            inputField.isEnabled = true
            messageSendButton?.isEnabled = true
            messageSendButton?.backgroundColor = LocationMapStyle.brand
            if retryWhenOnline {
                retryWhenOnline = false
                beginAnswerGeneration()
            }
        }
    }

    func showOfflineBanner() {
        guard offlineBanner == nil else { return }
        let banner = UIStackView()
        banner.axis = .horizontal
        banner.alignment = .center
        banner.spacing = 8
        banner.isLayoutMarginsRelativeArrangement = true
        banner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        banner.backgroundColor = AppStyle.ink
        banner.layer.cornerRadius = 14
        let icon = UIImageView(image: UIImage(named: "ChatOfflineWifi")?.withRenderingMode(.alwaysOriginal))
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("인터넷 연결이 끊겼어요. 연결되면 자동으로 다시 시도해요.", size: 12, color: .white)
        banner.addArrangedSubview(icon)
        banner.addArrangedSubview(message)
        messagesStack.insertArrangedSubview(banner, at: min(1, messagesStack.arrangedSubviews.count))
        offlineBanner = banner
    }

    func showPendingStatus() {
        guard pendingStatusRow == nil else { return }
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 6
        let clock = UIImageView(image: UIImage(named: "ChatOfflineClock")?.withRenderingMode(.alwaysOriginal))
        clock.widthAnchor.constraint(equalToConstant: 14).isActive = true
        clock.heightAnchor.constraint(equalToConstant: 14).isActive = true
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(clock)
        row.addArrangedSubview(AppStyle.label("연결되면 전송돼요", size: 12, color: AppStyle.muted))
        messagesStack.addArrangedSubview(row)
        pendingStatusRow = row
    }

    func sendMessage() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        guard !isOffline || isLocationMeasurementRequest(text) else { return }
        inputField.text = nil
        guard !isLocationMeasurementRequest(text) else {
            beginLocationMeasurement(question: text)
            return
        }
        addMessage(text, outgoing: true)
        beginAnswerGeneration()
    }

    func beginAnswerGeneration() {
        if isOffline {
            retryWhenOnline = true
            showPendingStatus()
            return
        }
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("Frontend 시작 순서", size: 18, weight: .semibold)
        let partial = AppStyle.label("처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요. HTML·CSS로 간단한 페이지를", size: 15)
        let cursor = UIView()
        cursor.backgroundColor = AppStyle.blue
        cursor.widthAnchor.constraint(equalToConstant: 2).isActive = true
        cursor.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let content = UIStackView(arrangedSubviews: [title, partial, cursor])
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
        pendingAnswerCard = card
        stopAnswerButton.isHidden = false
        inputField.placeholder = "답변을 만드는 중이에요…"
        inputField.isEnabled = false

        let work = DispatchWorkItem { [weak self] in self?.finishAnswerGeneration() }
        generationTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }

    func beginAttachmentAnalysis(attachments: [ChatAttachmentItem]) {
        attachmentResponseState.isResponse = true
        guard !isOffline else {
            showAttachmentAnalysisFailure()
            return
        }

        let imageCount = attachments.filter { $0.image != nil }.count
        let pdfCount = attachments.count - imageCount
        let countDescription = [
            imageCount > 0 ? "이미지 \(imageCount)장" : nil,
            pdfCount > 0 ? "PDF \(pdfCount)개" : nil
        ].compactMap { $0 }.joined(separator: ", ")

        let card = makeAttachmentAnalysisCard(countDescription: countDescription)
        messagesStack.addArrangedSubview(card)
        attachmentResponseState.pendingCard = card
        stopAnswerButton.isHidden = false
        inputField.placeholder = "자료를 확인하는 중이에요…"
        inputField.isEnabled = false

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.removePendingAttachmentAnalysisCard()
            self.finishAnswerGeneration()
        }
        generationTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }

    private func makeAttachmentAnalysisCard(countDescription: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let dots = UIStackView()
        dots.axis = .horizontal
        dots.alignment = .center
        dots.spacing = 4
        for _ in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = AppStyle.blue
            dot.layer.cornerRadius = 3
            dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
            dots.addArrangedSubview(dot)
        }
        let title = AppStyle.label("자료를 분석하고 있어요…", size: 15, weight: .medium)
        let detail = AppStyle.label("첨부 자료 확인 중 · \(countDescription)", size: 12, color: AppStyle.muted)
        let labels = UIStackView(arrangedSubviews: [title, detail])
        labels.axis = .vertical
        labels.spacing = 2
        let content = UIStackView(arrangedSubviews: [dots, labels])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            dots.widthAnchor.constraint(equalToConstant: 32)
        ])
        return card
    }

    func removePendingAttachmentAnalysisCard() {
        guard let pendingCard = attachmentResponseState.pendingCard else { return }
        messagesStack.removeArrangedSubview(pendingCard)
        pendingCard.removeFromSuperview()
        attachmentResponseState.pendingCard = nil
    }

    func showAttachmentAnalysisFailure() {
        guard attachmentResponseState.failureCard == nil else { return }
        let card = makeAttachmentAnalysisFailureCard()
        messagesStack.addArrangedSubview(card)
        attachmentResponseState.failureCard = card
    }

    private func makeAttachmentAnalysisFailureCard() -> UIView {
        let card = UIView()
        let alertIcon = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        alertIcon.tintColor = UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1)
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let title = AppStyle.label("자료를 분석하지 못했어요", size: 15, weight: .medium,
            color: UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1))
        let heading = UIStackView(arrangedSubviews: [alertIcon, title])
        heading.axis = .horizontal
        heading.alignment = .center
        heading.spacing = 8
        let detail = AppStyle.label(
            "네트워크 상태를 확인한 뒤 다시 시도해 주세요. 첨부한 자료는 그대로 남아 있어요.",
            size: 14,
            weight: .medium,
            color: AppStyle.muted
        )
        detail.numberOfLines = 0
        let retry = UIButton(type: .system)
        retry.setTitle("다시 시도", for: .normal)
        retry.setTitleColor(AppStyle.muted, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        retry.contentHorizontalAlignment = .leading
        retry.addAction(UIAction { [weak self] _ in self?.retryAttachmentAnalysis() }, for: .touchUpInside)
        let content = UIStackView(arrangedSubviews: [heading, detail, retry])
        content.axis = .vertical
        content.spacing = 6
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            retry.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        return card
    }

    private func retryAttachmentAnalysis() {
        guard !isOffline, let attachments = attachmentResponseState.lastSentAttachments else { return }
        attachmentResponseState.failureCard?.removeFromSuperview()
        attachmentResponseState.failureCard = nil
        beginAttachmentAnalysis(attachments: attachments)
    }

    func finishAnswerGeneration() {
        let isAttachmentResponse = attachmentResponseState.isResponse
        let attachments = attachmentResponseState.lastSentAttachments
        let attachmentSourceFileName = attachments?.first(where: { $0.image == nil })?.fileName
            ?? attachments?.first?.fileName
            ?? "첨부 자료"
        generationTimer = nil
        removePendingAttachmentAnalysisCard()
        attachmentResponseState.failureCard?.removeFromSuperview()
        attachmentResponseState.failureCard = nil
        attachmentResponseState.lastSentAttachments = nil
        attachmentResponseState.isResponse = false
        if let pendingAnswerCard {
            messagesStack.removeArrangedSubview(pendingAnswerCard)
            pendingAnswerCard.removeFromSuperview()
            self.pendingAnswerCard = nil
        }
        stopAnswerButton.isHidden = true
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
        if isAttachmentResponse {
            resizeSentAttachmentThumbnails(to: 56)
            addAttachmentFormattedAnswer(sourceFileName: attachmentSourceFileName)
        } else {
            addFormattedAnswer()
        }
    }

    func stopAnswerGeneration() {
        generationTimer?.cancel()
        generationTimer = nil
        removePendingAttachmentAnalysisCard()
        attachmentResponseState.failureCard?.removeFromSuperview()
        attachmentResponseState.failureCard = nil
        attachmentResponseState.lastSentAttachments = nil
        attachmentResponseState.isResponse = false
        stopAnswerButton.isHidden = true
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
        if let pendingAnswerCard {
            messagesStack.removeArrangedSubview(pendingAnswerCard)
            pendingAnswerCard.removeFromSuperview()
            self.pendingAnswerCard = nil
        }
        addAnswerFailure()
    }

}
