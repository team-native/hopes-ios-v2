import UIKit

@MainActor
final class InquiryViewController: AppPageViewController, UITextFieldDelegate, UITextViewDelegate {
    let primaryTextColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    let secondaryTextColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let emailField = UITextField()
    let messageView = UITextView()
    let messagePlaceholder = "예: 답변이 너무 짧게 나와요."
    let messageErrorPlaceholder = "예: 답변이 너무 짧게 나와요."
    let focusedPreviewMessage = "추천 질문이 학과를 바꿔도 그대로 나와요"
    let showsInputPreview = ProcessInfo.processInfo.arguments.contains("--inquiry-input-preview")
    let showsErrorPreview = ProcessInfo.processInfo.arguments.contains("--inquiry-error-preview")
    var messageHeightConstraint: NSLayoutConstraint!
    var messageMinimumHeightConstraint: NSLayoutConstraint!
    var submitButtonBottomConstraint: NSLayoutConstraint?
    var emailErrorRow: UIView!
    var messageErrorRow: UIView!
    var hasEmailError = false
    var hasMessageError = false
    var keyboardObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 16
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        let header = makeHeader()
        contentStack.addArrangedSubview(header)
        contentStack.addArrangedSubview(makeContactCard())
        contentStack.addArrangedSubview(makeMailInfo())
        pinSubmitButtonToBottom()

        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let userInfo = notification.userInfo ?? [:]
            let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey]
            let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey]
            guard let frame = frameValue as? CGRect, let duration = durationValue as? TimeInterval else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                let keyboardFrame = self.view.convert(frame, from: nil)
                let safeAreaBottom = self.view.bounds.maxY - self.view.safeAreaInsets.bottom
                let overlap = max(0, safeAreaBottom - keyboardFrame.minY)
                self.submitButtonBottomConstraint?.constant = -(16 + overlap)
                UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState) {
                    self.view.layoutIfNeeded()
                }
            }
        }

        if showsErrorPreview {
            emailField.text = "s26055@gsm"
            messageView.text = messageErrorPlaceholder
            messageView.textColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            messageHeightConstraint.constant = 150
            displayValidationErrors(emailInvalid: true, messageEmpty: true)
        } else if showsInputPreview {
            DispatchQueue.main.async { [weak self] in
                self?.messageView.becomeFirstResponder()
            }
        }
    }

    deinit {
        if let keyboardObserver {
            NotificationCenter.default.removeObserver(keyboardObserver)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderWidth = 1.5
        textView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
        guard textView.text == messagePlaceholder || textView.text == messageErrorPlaceholder else { return }
        textView.text = ""
        textView.textColor = primaryTextColor
        if hasMessageError {
            hasMessageError = false
            messageErrorRow.isHidden = true
            messageView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
            messageMinimumHeightConstraint.constant = 160
            messageHeightConstraint.constant = 160
        }
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText replacement: String
    ) -> Bool {
        guard showsInputPreview, textView.text == focusedPreviewMessage else { return true }
        textView.text = ""
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.textColor = primaryTextColor
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        messageView.becomeFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard !hasEmailError else { return }
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard !hasEmailError else { return }
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        guard textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        textView.text = messagePlaceholder
        textView.textColor = secondaryTextColor
        messageMinimumHeightConstraint.constant = 160
        messageHeightConstraint.constant = 160
    }

    func textViewDidChange(_ textView: UITextView) {
        if hasMessageError, !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasMessageError = false
            messageErrorRow.isHidden = true
            messageView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
            messageMinimumHeightConstraint.constant = 160
        }
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let measuredHeight = textView.sizeThatFits(fittingSize).height
        let minimumHeight: CGFloat = hasMessageError ? 150 : 160
        messageMinimumHeightConstraint.constant = minimumHeight
        messageHeightConstraint.constant = min(max(minimumHeight, measuredHeight), 220)
    }

    func submit() {
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
        push(InquiryCompletionViewController(email: email))
    }

    func displayValidationErrors(emailInvalid: Bool, messageEmpty: Bool) {
        hasEmailError = emailInvalid
        hasMessageError = messageEmpty
        emailErrorRow.isHidden = !emailInvalid
        messageErrorRow.isHidden = !messageEmpty
        emailField.layer.borderWidth = emailInvalid ? 1.5 : 1
        emailField.layer.borderColor = (emailInvalid
            ? UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
            : UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)).cgColor
        messageView.layer.borderColor = (messageEmpty
            ? UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
            : UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)).cgColor
        messageView.layer.borderWidth = messageEmpty ? 1.5 : 1
        if messageEmpty {
            messageView.text = messageErrorPlaceholder
            messageView.textColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            messageMinimumHeightConstraint.constant = 150
            messageHeightConstraint.constant = 150
        }
    }

    @objc func emailDidChange() {
        guard hasEmailError else { return }
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard email.contains("@") else { return }
        hasEmailError = false
        emailErrorRow.isHidden = true
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
    }
}
