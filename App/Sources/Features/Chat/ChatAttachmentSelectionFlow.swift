import UIKit

@MainActor
extension ChatConversationViewController {
    func addAttachments(_ attachments: [ChatAttachmentItem]) {
        let proposedAttachments = selectedAttachments + attachments
        if proposedAttachments.count > ChatAttachmentPolicy.maximumCount {
            let error = ChatAttachmentLimitError.tooManyAttachments
            if selectedAttachments.isEmpty {
                presentMessage(error.localizedDescription)
            } else {
                attachmentTrayView?.validationError = error
            }
            return
        }
        selectedAttachments.append(contentsOf: attachments)
        refreshAttachmentTray()
    }

    func refreshAttachmentTray() {
        guard let attachmentTrayView, let composerView else { return }
        let hasAttachments = !selectedAttachments.isEmpty
        do {
            try ChatAttachmentPolicy.validate(selectedAttachments)
            attachmentTrayView.validationError = nil
        } catch let error as ChatAttachmentLimitError {
            attachmentTrayView.validationError = error
        } catch {
            attachmentTrayView.validationError = .unreadableFile
        }
        attachmentTrayView.attachments = selectedAttachments
        attachmentTrayView.isHidden = !hasAttachments
        composerView.isHidden = hasAttachments
        composerScrollConstraint?.isActive = !hasAttachments
        attachmentTrayScrollConstraint?.isActive = hasAttachments
    }

    func sendAttachmentQuestion(_ question: String) async -> Bool {
        guard !selectedAttachments.isEmpty else { return false }
        let attachments = selectedAttachments
        let uploads: [ChatAttachmentUploadPayload]
        do {
            uploads = try await Self.prepareAttachmentUploads(for: attachments)
        } catch let error as ChatAttachmentLimitError {
            attachmentTrayView?.validationError = error
            return false
        } catch {
            attachmentTrayView?.validationError = .unreadableFile
            return false
        }
        guard selectedAttachments.map(\.id) == attachments.map(\.id) else { return false }

        attachmentTrayView?.validationError = nil
        attachmentResponseState.uploadedAttachmentIDs.removeAll()
        attachmentResponseState.lastSentAttachments = attachments
        attachmentResponseState.messageClientRequestId = UUID().uuidString
        addSentAttachments(attachments)
        addUserMessage(question)
        selectedAttachments.removeAll()
        refreshAttachmentTray()
        pendingQuestion = question
        beginAttachmentAnalysis(attachments: attachments, uploads: uploads)
        return true
    }
}
