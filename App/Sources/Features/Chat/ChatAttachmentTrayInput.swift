import UIKit

@MainActor
extension ChatAttachmentTrayView {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        inputContainer.layer.borderColor = ChatDetailPalette.brandBorder.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        inputContainer.layer.borderColor = ChatDetailPalette.border.cgColor
    }

    func sendQuestion() {
        guard !isSending, !attachments.contains(where: { !$0.isSupported }) else { return }
        let question = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !question.isEmpty else { return }
        isSending = true
        attachmentsStack.isUserInteractionEnabled = false
        updateAttachments()
        Task { @MainActor [weak self] in
            guard let self else { return }
            let accepted = await self.onSend?(question) ?? false
            self.isSending = false
            self.attachmentsStack.isUserInteractionEnabled = true
            if accepted {
                let currentQuestion = self.inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if currentQuestion == question {
                    self.inputField.text = "이 자료 요약해줘"
                }
                self.validationError = nil
            }
            self.updateAttachments()
        }
    }
}
