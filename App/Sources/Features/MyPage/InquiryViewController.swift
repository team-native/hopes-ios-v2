import UIKit

@MainActor
final class InquiryViewController: AppPageViewController, UITextFieldDelegate, UITextViewDelegate {
    private let primaryTextColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    private let secondaryTextColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    private let emailField = UITextField()
    private let messageView = UITextView()
    private let messagePlaceholder = "문의 내용을 자세히 적어주세요"
    private let messageErrorPlaceholder = "예: 답변이 너무 짧게 나와요."
    private let focusedPreviewMessage = "추천 질문이 학과를 바꿔도 그대로 나와요"
    private let showsInputPreview = ProcessInfo.processInfo.arguments.contains("--inquiry-input-preview")
    private let showsErrorPreview = ProcessInfo.processInfo.arguments.contains("--inquiry-error-preview")
    private var messageHeightConstraint: NSLayoutConstraint!
    private var emailErrorRow: UIView!
    private var messageErrorRow: UIView!
    private var hasEmailError = false
    private var hasMessageError = false
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

        if showsErrorPreview {
            emailField.text = "s26055@gsm"
            messageView.text = messageErrorPlaceholder
            messageView.textColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            messageHeightConstraint.constant = 150
            displayValidationErrors(emailInvalid: true, messageEmpty: true)
        } else {
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
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    private func makeHeader() -> UIView {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "inquiry-chevron-left"), for: .normal)
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
        emailErrorRow = makeErrorRow("이메일 형식이 올바르지 않아요.")
        let emailGroup = makeFieldGroup(label: emailLabel, field: emailField, errorRow: emailErrorRow)
        let messageLabel = AppStyle.label("문의 내용", size: 14, weight: .medium, color: secondaryTextColor)
        emailLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        messageLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        messageErrorRow = makeErrorRow("문의 내용을 입력해 주세요.")
        let messageGroup = makeFieldGroup(label: messageLabel, field: messageView, errorRow: messageErrorRow)

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

    private func makeFieldGroup(label: UILabel, field: UIView, errorRow: UIView) -> UIView {
        let group = UIStackView(arrangedSubviews: [label, field, errorRow])
        group.axis = .vertical
        group.spacing = 6
        group.setCustomSpacing(4, after: field)
        return group
    }

    private func makeErrorRow(_ message: String) -> UIView {
        let icon = UIImageView(image: UIImage(named: "inquiry-error-alert"))
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let label = AppStyle.label(
            message,
            size: 12,
            color: UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        )
        label.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        row.isHidden = true
        return row
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
        emailField.addTarget(self, action: #selector(emailDidChange), for: .editingChanged)
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
        guard textView.text == messagePlaceholder || textView.text == messageErrorPlaceholder else { return }
        textView.text = ""
        textView.textColor = primaryTextColor
        if hasMessageError {
            hasMessageError = false
            messageErrorRow.isHidden = true
            messageView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
            messageHeightConstraint.constant = 55
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

    func textViewDidEndEditing(_ textView: UITextView) {
        guard textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        textView.text = messagePlaceholder
        textView.textColor = secondaryTextColor
        messageHeightConstraint.constant = 55
    }

    func textViewDidChange(_ textView: UITextView) {
        if hasMessageError, !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasMessageError = false
            messageErrorRow.isHidden = true
            messageView.layer.borderColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1).cgColor
        }
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let measuredHeight = textView.sizeThatFits(fittingSize).height
        messageHeightConstraint.constant = min(max(55, measuredHeight), 160)
    }

    private func submit() {
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

    private func displayValidationErrors(emailInvalid: Bool, messageEmpty: Bool) {
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
        if messageEmpty {
            messageView.text = messageErrorPlaceholder
            messageView.textColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
            messageHeightConstraint.constant = 150
        }
    }

    @objc private func emailDidChange() {
        guard hasEmailError else { return }
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard email.contains("@") else { return }
        hasEmailError = false
        emailErrorRow.isHidden = true
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
    }
}

@MainActor
final class InquiryCompletionViewController: UIViewController {
    private let email: String

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "inquiry-chevron-left"), for: .normal)
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("문의하기", size: 18, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1))
        let header = UIStackView(arrangedSubviews: [backButton, title])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let badge = UIView()
        badge.backgroundColor = .white
        badge.layer.cornerRadius = 44
        badge.layer.borderWidth = 1
        badge.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        badge.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.09).cgColor
        badge.layer.shadowOpacity = 1
        badge.layer.shadowRadius = 14
        badge.layer.shadowOffset = CGSize(width: 0, height: 8)

        let mailIcon = UIImageView(image: UIImage(named: "inquiry-mail"))
        mailIcon.contentMode = .scaleAspectFit
        mailIcon.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(mailIcon)

        let titleText = NSMutableAttributedString(string: "문의를 ", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        ])
        titleText.append(NSAttributedString(string: "보냈어요", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        ]))
        let doneTitle = UILabel()
        doneTitle.attributedText = titleText
        doneTitle.textAlignment = .center

        let description = AppStyle.label(
            "\(email)로 답변을 보내드릴게요.",
            size: 14,
            weight: .medium,
            color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        )
        description.textAlignment = .center

        let content = UIStackView(arrangedSubviews: [badge, doneTitle, description])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)

        let confirm = AppStyle.button("확인", primary: true) { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        confirm.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        confirm.layer.cornerRadius = 12
        confirm.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        confirm.heightAnchor.constraint(equalToConstant: 50).isActive = true
        confirm.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirm)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            badge.widthAnchor.constraint(equalToConstant: 88),
            badge.heightAnchor.constraint(equalToConstant: 88),
            mailIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            mailIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            mailIcon.widthAnchor.constraint(equalToConstant: 36),
            mailIcon.heightAnchor.constraint(equalToConstant: 36),
            content.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            confirm.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirm.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirm.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            confirm.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
