import UIKit

@MainActor
final class InquiryViewController: AppPageViewController, UITextViewDelegate {
    private let emailField = UITextField()
    private let messageView = UITextView()
    private let placeholder = "문의 내용을 자세히 적어주세요"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "문의하기"
        addHeading("무엇을 도와드릴까요?", subtitle: "문의 내용을 남겨주시면 확인 후 답변드릴게요")
        contentStack.addArrangedSubview(AppStyle.label("답변 받을 이메일", size: 14, weight: .semibold))
        emailField.text = UserProfileStore.shared.email
        emailField.keyboardType = .emailAddress
        emailField.borderStyle = .roundedRect
        emailField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        contentStack.addArrangedSubview(emailField)

        contentStack.addArrangedSubview(AppStyle.label("문의 내용", size: 14, weight: .semibold))
        messageView.text = placeholder
        messageView.textColor = AppStyle.muted
        messageView.font = .systemFont(ofSize: 15)
        messageView.layer.cornerRadius = 12
        messageView.layer.borderWidth = 1
        messageView.layer.borderColor = AppStyle.line.cgColor
        messageView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        messageView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        messageView.delegate = self
        contentStack.addArrangedSubview(messageView)

        contentStack.addArrangedSubview(AppStyle.button("문의 보내기", primary: true) { [weak self] in self?.submit() })
        contentStack.addArrangedSubview(AppStyle.label("문의: gsm-chatbot@gsm.hs.kr", size: 13, color: AppStyle.muted))
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = ""
            textView.textColor = AppStyle.ink
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholder
            textView.textColor = AppStyle.muted
        }
    }

    private func submit() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageView.text == placeholder ? "" : messageView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.contains("@"), !message.isEmpty else {
            showMessage("이메일과 문의 내용을 확인해주세요")
            return
        }
        showMessage("문의 접수 UI를 완료했어요. 문의 API 연결 후 실제 전송됩니다")
    }
}
