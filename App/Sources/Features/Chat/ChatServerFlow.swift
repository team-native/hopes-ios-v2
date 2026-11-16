import UIKit

@MainActor
extension ChatConversationViewController {
    func requestServerAnswer(question: String) {
        answerTask?.cancel()
        answerTask = Task { [weak self] in
            do {
                guard let self else { return }
                let chatID = try await self.ensureConversation(title: question)
                let payload = SendMessagePayload(
                    content: question,
                    attachmentIds: [],
                    departmentId: ChatContextStore.departmentID,
                    specialtyId: ChatContextStore.specialtyID,
                    clientRequestId: UUID().uuidString
                )
                let chat = try await ChatAPI.send(chatID: chatID, payload: payload)
                guard !Task.isCancelled else { return }
                self.answerTask = nil
                self.serverAnswer = chat.messages.last(where: { !$0.isUser })?.content ?? ""
                self.finishAnswerGeneration()
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.answerTask = nil
                if (error as? APIError) == .network {
                    self.updateNetworkStatus(isOffline: true)
                    self.retryWhenOnline = true
                    self.stopAnswerButton.isHidden = true
                    self.removePendingAnswerCard()
                    self.showPendingStatus()
                } else {
                    self.stopAnswerGeneration()
                }
            }
        }
    }

    func requestAttachmentAnswer(attachments: [ChatAttachmentItem], question: String) {
        answerTask?.cancel()
        answerTask = Task { [weak self] in
            do {
                var attachmentIDs: [Int64] = []
                for attachment in attachments {
                    guard !Task.isCancelled else { return }
                    guard let upload = await Self.uploadData(for: attachment) else { throw APIError.decoding }
                    let result = try await AttachmentAPI.upload(
                        data: upload.data, fileName: attachment.fileName, mimeType: upload.mimeType
                    )
                    attachmentIDs.append(result.id)
                }
                guard let self else { return }
                let chatID = try await self.ensureConversation(title: question)
                let payload = SendMessagePayload(
                    content: question,
                    attachmentIds: attachmentIDs,
                    departmentId: ChatContextStore.departmentID,
                    specialtyId: ChatContextStore.specialtyID,
                    clientRequestId: UUID().uuidString
                )
                let chat = try await ChatAPI.send(chatID: chatID, payload: payload)
                guard !Task.isCancelled else { return }
                self.answerTask = nil
                self.serverAnswer = chat.messages.last(where: { !$0.isUser })?.content ?? ""
                self.removePendingAttachmentAnalysisCard()
                self.finishAnswerGeneration()
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.answerTask = nil
                self.showAttachmentAnalysisFailure()
            }
        }
    }

    nonisolated static func uploadData(for attachment: ChatAttachmentItem) async -> (data: Data, mimeType: String)? {
        if let image = attachment.image, let data = image.jpegData(compressionQuality: 0.85) {
            return (data, "image/jpeg")
        }
        if let url = attachment.url {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return (data, "application/pdf")
        }
        return nil
    }

    func shareAnswer() {
        let answer = lastAnswerText
            ?? "Frontend 시작 순서\nHTML·CSS로 간단한 페이지 만들기 → JavaScript 기초 문법 익히기 → React로 작은 프로젝트 완성하기"
        let activity = UIActivityViewController(activityItems: [answer], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        present(activity, animated: true)
    }

    func ensureConversation(title: String) async throws -> Int64 {
        if let conversationID { return conversationID }
        let chat = try await ChatAPI.create(title: title)
        conversationID = chat.id
        return chat.id
    }

    func loadConversation(id: Int64) {
        Task { [weak self] in
            guard let chat = try? await ChatAPI.detail(id: id), let self else { return }
            let messages = chat.messages.sorted { $0.id < $1.id }
            for (index, message) in messages.enumerated() {
                if message.isUser {
                    self.addUserMessage(message.content)
                } else {
                    self.addMarkdownAnswer(message.content, showsActions: index == messages.count - 1)
                }
            }
        }
    }

    func removePendingAnswerCard() {
        guard let pendingAnswerCard else { return }
        messagesStack.removeArrangedSubview(pendingAnswerCard)
        pendingAnswerCard.removeFromSuperview()
        self.pendingAnswerCard = nil
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
    }

    func addMarkdownAnswer(_ markdown: String, showsActions: Bool = true) {
        lastAnswerText = markdown
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        card.layer.borderColor = ChatDetailPalette.border.cgColor
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = MarkdownText.attributed(markdown, size: 15, color: ChatDetailPalette.ink)
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        messagesStack.addArrangedSubview(card)
        if showsActions {
            addAnswerActions()
        }
    }
}

enum MarkdownText {
    static func attributed(_ markdown: String, size: CGFloat, color: UIColor) -> NSAttributedString {
        let normalized = markdown
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            .map { line -> String in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("#") else { return line }
                let text = trimmed.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
                return text.isEmpty ? "" : "**\(text)**"
            }
            .joined(separator: "\n")
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let parsed = (try? NSMutableAttributedString(markdown: normalized, options: options))
            ?? NSMutableAttributedString(string: normalized)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        let range = NSRange(location: 0, length: parsed.length)
        parsed.addAttribute(.foregroundColor, value: color, range: range)
        parsed.addAttribute(.paragraphStyle, value: paragraph, range: range)
        parsed.enumerateAttribute(.inlinePresentationIntent, in: range) { value, subrange, _ in
            let intent = (value as? NSNumber).map { InlinePresentationIntent(rawValue: $0.uintValue) } ?? []
            let weight: UIFont.Weight = intent.contains(.stronglyEmphasized) ? .semibold : .regular
            let font = intent.contains(.code)
                ? UIFont.monospacedSystemFont(ofSize: size - 1, weight: .regular)
                : UIFont.systemFont(ofSize: size, weight: weight)
            parsed.addAttribute(.font, value: font, range: subrange)
        }
        return parsed
    }
}

enum ChatContextStore {
    static var departmentID: Int64? {
        CatalogAPI.departmentID(for: UserDefaults.standard.string(forKey: "chat.selectedDepartment"))
    }

    static var specialtyID: Int64? {
        CatalogAPI.specialtyID(for: UserDefaults.standard.string(forKey: "chat.selectedMajor"))
    }
}
