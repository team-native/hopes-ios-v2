import UIKit
import PDFKit

struct ChatAttachmentUploadPayload: Sendable {
    let fileName: String
    let data: Data
    let mimeType: String
    let clientRequestId: String
}

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
                    clientRequestId: UUID().uuidString,
                    specialtyIds: ChatContextStore.specialtyIDs
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

    func requestAttachmentAnswer(uploads: [ChatAttachmentUploadPayload], question: String) {
        answerTask?.cancel()
        let messageClientRequestId = attachmentResponseState.messageClientRequestId ?? UUID().uuidString
        attachmentResponseState.messageClientRequestId = messageClientRequestId
        answerTask = Task { [weak self] in
            do {
                guard let self else { return }
                let attachmentIDs = try await self.uploadAttachmentsWithProgress(uploads)
                guard !Task.isCancelled else {
                    return
                }
                let chatID = try await self.ensureConversation(title: question)
                guard !Task.isCancelled else {
                    return
                }
                let payload = SendMessagePayload(
                    content: question,
                    attachmentIds: attachmentIDs,
                    departmentId: ChatContextStore.departmentID,
                    specialtyId: ChatContextStore.specialtyID,
                    clientRequestId: messageClientRequestId,
                    specialtyIds: ChatContextStore.specialtyIDs
                )
                let chat = try await ChatAPI.send(chatID: chatID, payload: payload)
                guard !Task.isCancelled else {
                    return
                }
                self.answerTask = nil
                self.serverAnswer = chat.messages.last(where: { !$0.isUser })?.content ?? ""
                self.removePendingAttachmentAnalysisCard()
                self.finishAnswerGeneration()
            } catch {
                guard let self, !Task.isCancelled else { return }
                if let failedUpload = uploads.first(where: {
                    self.attachmentResponseState.uploadedAttachmentIDs[$0.clientRequestId] == nil
                }) {
                    self.updateAttachmentUploadFailed(clientRequestId: failedUpload.clientRequestId)
                }
                self.answerTask = nil
                self.showAttachmentAnalysisFailure()
            }
        }
    }

    nonisolated static func prepareAttachmentUploads(
        for attachments: [ChatAttachmentItem]
    ) async throws -> [ChatAttachmentUploadPayload] {
        try ChatAttachmentPolicy.validate(attachments)
        var totalBytes = 0
        var uploads: [ChatAttachmentUploadPayload] = []
        uploads.reserveCapacity(attachments.count)

        for attachment in attachments {
            guard let upload = await uploadData(for: attachment) else {
                throw ChatAttachmentLimitError.unreadableFile
            }
            try ChatAttachmentPolicy.validateFileSize(upload.data.count)
            totalBytes += upload.data.count
            try ChatAttachmentPolicy.validateTotalSize(totalBytes)

            if let image = attachment.image {
                let width = image.cgImage?.width ?? Int((image.size.width * image.scale).rounded())
                let height = image.cgImage?.height ?? Int((image.size.height * image.scale).rounded())
                try ChatAttachmentPolicy.validateImageDimensions(width: width, height: height)
            } else {
                guard let document = PDFDocument(data: upload.data), !document.isLocked else {
                    throw ChatAttachmentLimitError.unreadableFile
                }
                try ChatAttachmentPolicy.validatePDFPages(document.pageCount)
            }

            uploads.append(ChatAttachmentUploadPayload(
                fileName: attachment.fileName,
                data: upload.data,
                mimeType: upload.mimeType,
                clientRequestId: attachment.id.uuidString
            ))
        }
        return uploads
    }

    nonisolated static func deleteUnsentAttachments(_ ids: [Int64]) async {
        await Task.detached {
            for id in ids {
                try? await AttachmentAPI.delete(id: id)
            }
        }.value
    }

    func uploadAttachmentsWithProgress(_ uploads: [ChatAttachmentUploadPayload]) async throws -> [Int64] {
        for upload in uploads {
            try Task.checkCancellation()
            if attachmentResponseState.uploadedAttachmentIDs[upload.clientRequestId] != nil {
                updateAttachmentUploadCompleted(clientRequestId: upload.clientRequestId)
                continue
            }

            do {
                let result = try await AttachmentAPI.upload(
                    data: upload.data,
                    fileName: upload.fileName,
                    mimeType: upload.mimeType,
                    clientRequestId: upload.clientRequestId,
                    onProgress: { [weak self] sent, expected in
                        Task { @MainActor [weak self] in
                            self?.updateAttachmentUploadProgress(
                                clientRequestId: upload.clientRequestId,
                                sent: sent,
                                expected: expected
                            )
                        }
                    }
                )
                guard result.status == "READY" else { throw APIError.decoding }
                attachmentResponseState.uploadedAttachmentIDs[upload.clientRequestId] = result.id
                updateAttachmentUploadCompleted(clientRequestId: upload.clientRequestId)
            } catch {
                updateAttachmentUploadFailed(clientRequestId: upload.clientRequestId)
                throw error
            }
        }
        let ids = uploads.compactMap { attachmentResponseState.uploadedAttachmentIDs[$0.clientRequestId] }
        guard ids.count == uploads.count else { throw APIError.decoding }
        return ids
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

    func loadRelatedQuestions(excluding question: String?) {
        guard AccessTokenStore.shared.hasToken, let actionRow = messagesStack.arrangedSubviews.last else { return }
        let defaults = UserDefaults.standard
        Task { [weak self] in
            let result = try? await CatalogAPI.recommendations(
                department: defaults.string(forKey: "chat.selectedDepartment"),
                specialties: ChatMajorSelection.load(defaults: defaults),
                refreshToken: nil,
                excludeIDs: []
            )
            guard let self, let result, self.messagesStack.arrangedSubviews.last === actionRow else { return }
            let questions = Self.relatedQuestions(from: result.items.map(\.content), excluding: question)
            guard !questions.isEmpty else { return }
            self.addRelatedQuestions(questions)
        }
    }

    nonisolated static func relatedQuestions(from candidates: [String], excluding question: String?) -> [String] {
        let current = question?.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        return candidates
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != current && seen.insert($0).inserted }
            .prefix(2)
            .map { $0 }
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

        let content = makeMarkdownAnswerStack(markdown)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        card.accessibilityHint = "길게 눌러 답변을 복사할 수 있어요"
        card.addGestureRecognizer(ChatAnswerCopyGesture(markdown: markdown) { [weak self] text in
            UIPasteboard.general.string = text
            self?.showToast("답변을 복사했어요")
        })
        messagesStack.addArrangedSubview(card)
        if showsActions {
            addAnswerActions()
            loadRelatedQuestions(excluding: pendingQuestion)
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

    static var specialtyIDs: [Int64] {
        CatalogAPI.specialtyIDs(for: ChatMajorSelection.load())
    }

    static var specialtyID: Int64? { specialtyIDs.first }
}
