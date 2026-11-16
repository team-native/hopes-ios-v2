import UIKit

@MainActor
extension InquiryViewController {
    private var isVisibleForInquiryResponse: Bool {
        viewIfLoaded?.window != nil && navigationController?.topViewController === self
    }

    func submit() {
        guard !isSubmitting else { return }
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isPlaceholder = messageView.text == messagePlaceholder || messageView.text == messageErrorPlaceholder
        let message = isPlaceholder || (showsInputPreview && messageView.text == focusedPreviewMessage)
            ? ""
            : messageView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailInvalid = !email.contains("@")
        let messageEmpty = message.isEmpty
        guard !emailInvalid, !messageEmpty else {
            view.endEditing(true)
            displayValidationErrors(emailInvalid: emailInvalid, messageEmpty: messageEmpty)
            return
        }
        view.endEditing(true)
        isSubmitting = true
        submitButton?.isEnabled = false
        Task { [weak self] in
            guard let self else { return }
            defer {
                self.isSubmitting = false
                self.submitButton?.isEnabled = true
            }
            do {
                try await self.inquirySender(email, message)
            } catch {
                guard self.isVisibleForInquiryResponse else { return }
                self.showMessage((error as? APIError)?.message ?? "문의를 보내지 못했어요.")
                return
            }
            guard self.isVisibleForInquiryResponse else { return }
            self.push(InquiryCompletionViewController(email: email))
        }
    }
}
