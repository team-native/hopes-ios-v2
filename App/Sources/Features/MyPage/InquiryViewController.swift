import UIKit

@MainActor
final class InquiryViewController: AppPageViewController, UITextFieldDelegate, UITextViewDelegate {
    private let primaryTextColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    private let secondaryTextColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    private let emailField = UITextField()
    private let messageView = UITextView()
    private let messagePlaceholder = "문의 내용을 자세히 적어주세요"
    private let focusedPreviewMessage = "추천 질문이 학과를 바꿔도 그대로 나와요"
    private let showsInputPreview = ProcessInfo.processInfo.arguments.contains("--inquiry-input-preview")
    private var messageHeightConstraint: NSLayoutConstraint!
    private var keyboardObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 14
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        let header = makeHeader()
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(12, after: header)
        contentStack.addArrangedSubview(makeContactCard())

        let submitButton = AppStyle.button("문의 보내기", primary: true) { [weak self] in
            self?.submit()
        }
        submitButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        submitButton.layer.cornerRadius = 12
        submitButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(submitButton)

        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
            let keyboardFrame = self.view.convert(frame, from: nil)
            let overlap = max(0, self.view.bounds.maxY - keyboardFrame.minY)
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.messageView.becomeFirstResponder()
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
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    private func makeHeader() -> UIView {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = primaryTextColor
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let titleLabel = AppStyle.label("문의하기", size: 18, weight: .medium, color: primaryTextColor)
        let subtitleLabel = AppStyle.label("서비스 오류나 개선 의견을 보내요.", size: 12, color: secondaryTextColor)
        titleLabel.heightAnchor.constraint(equalToConstant: 26).isActive = true
        subtitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 0

        let header = UIStackView(arrangedSubviews: [backButton, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        return header
    }

    private func makeContactCard() -> UIView {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        configureEmailField()
        configureMessageView()

        let emailLabel = AppStyle.label("답변 받을 이메일", size: 14, weight: .medium, color: secondaryTextColor)
        let emailGroup = makeFieldGroup(label: emailLabel, field: emailField)
        let messageLabel = AppStyle.label("문의 내용", size: 14, weight: .medium, color: secondaryTextColor)
        emailLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        messageLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let messageGroup = makeFieldGroup(label: messageLabel, field: messageView)

        let fields = UIStackView(arrangedSubviews: [emailGroup, messageGroup])
        fields.axis = .vertical
        fields.spacing = 12
        fields.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fields)
        NSLayoutConstraint.activate([
            fields.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            fields.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            fields.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            fields.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeFieldGroup(label: UILabel, field: UIView) -> UIView {
        let group = UIStackView(arrangedSubviews: [label, field])
        group.axis = .vertical
        group.spacing = 6
        return group
    }

    private func configureEmailField() {
        emailField.text = UserProfileStore.shared.email
        emailField.font = .systemFont(ofSize: 15)
        emailField.textColor = primaryTextColor
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocorrectionType = .no
        emailField.autocapitalizationType = .none
        emailField.returnKeyType = .next
        emailField.delegate = self
        emailField.borderStyle = .none
        emailField.layer.cornerRadius = 16
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        emailField.leftViewMode = .always
        emailField.heightAnchor.constraint(equalToConstant: 54).isActive = true
    }

    private func configureMessageView() {
        messageView.text = showsInputPreview ? focusedPreviewMessage : messagePlaceholder
        messageView.textColor = showsInputPreview ? primaryTextColor : secondaryTextColor
        messageView.font = .systemFont(ofSize: 15)
        messageView.backgroundColor = .white
        messageView.layer.cornerRadius = 16
        messageView.layer.borderWidth = 1.5
        messageView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
        messageView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        messageView.textContainer.lineFragmentPadding = 0
        messageView.keyboardType = .default
        messageView.returnKeyType = .send
        messageView.autocorrectionType = .yes
        messageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
        messageHeightConstraint = messageView.heightAnchor.constraint(equalToConstant: 55)
        messageHeightConstraint.priority = .defaultHigh
        messageHeightConstraint.isActive = true
        messageView.delegate = self
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard textView.text == messagePlaceholder else { return }
        textView.text = ""
        textView.textColor = primaryTextColor
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

    func textViewDidEndEditing(_ textView: UITextView) {
        guard textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        textView.text = messagePlaceholder
        textView.textColor = secondaryTextColor
        messageHeightConstraint.constant = 55
    }

    func textViewDidChange(_ textView: UITextView) {
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let measuredHeight = textView.sizeThatFits(fittingSize).height
        messageHeightConstraint.constant = min(max(55, measuredHeight), 160)
    }

    private func submit() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageView.text == messagePlaceholder || (showsInputPreview && messageView.text == focusedPreviewMessage)
            ? ""
            : messageView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.contains("@"), !message.isEmpty else {
            showMessage("이메일과 문의 내용을 확인해주세요")
            return
        }
        showMessage("문의 접수 UI를 완료했어요. 문의 API 연결 후 실제 전송됩니다")
    }
}
