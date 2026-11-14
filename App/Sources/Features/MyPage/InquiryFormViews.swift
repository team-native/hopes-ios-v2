import UIKit

@MainActor
extension InquiryViewController {
    func makeHeader() -> UIView {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "inquiry-back-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backButton.accessibilityLabel = "뒤로"
        backButton.accessibilityIdentifier = "inquiry-back"
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

    func makeContactCard() -> UIView {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        configureEmailField()
        configureMessageView()

        let emailLabel = AppStyle.label("이메일", size: 14, weight: .medium, color: secondaryTextColor)
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

    func makeMailInfo() -> UIView {
        let chip = UIView()
        chip.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        chip.layer.cornerRadius = 12
        chip.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chip.widthAnchor.constraint(equalToConstant: 36),
            chip.heightAnchor.constraint(equalToConstant: 36)
        ])

        let icon = UIImageView(image: UIImage(named: "inquiry-mail-icon")?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18)
        ])

        let label = AppStyle.label("이메일 문의: gsm-chatbot@gsm.hs.kr", size: 14, weight: .medium, color: primaryTextColor)
        let row = UIStackView(arrangedSubviews: [chip, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        row.backgroundColor = .white
        row.layer.cornerRadius = 24
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        row.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        row.layer.shadowOpacity = 0.05
        row.layer.shadowRadius = 4
        row.layer.shadowOffset = CGSize(width: 0, height: 4)
        return row
    }

    func pinSubmitButtonToBottom() {
        let button = AppStyle.button("문의 보내기", primary: true) { [weak self] in
            self?.submit()
        }
        button.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.accessibilityIdentifier = "inquiry-submit"
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        if let bottomConstraint = view.constraints.first(where: {
            $0.firstItem === scrollView && $0.firstAttribute == .bottom
        }) {
            bottomConstraint.isActive = false
        }
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50),
            scrollView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -16)
        ])
        let bottomConstraint = button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -16)
        bottomConstraint.isActive = true
        submitButtonBottomConstraint = bottomConstraint
    }

    func makeFieldGroup(label: UILabel, field: UIView, errorRow: UIView) -> UIView {
        let group = UIStackView(arrangedSubviews: [label, field, errorRow])
        group.axis = .vertical
        group.spacing = 6
        group.setCustomSpacing(4, after: field)
        return group
    }

    func makeErrorRow(_ message: String) -> UIView {
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

    func configureEmailField() {
        emailField.text = nil
        emailField.attributedPlaceholder = NSAttributedString(string: "이메일", attributes: [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        ])
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

    func configureMessageView() {
        messageView.text = showsInputPreview ? focusedPreviewMessage : messagePlaceholder
        messageView.textColor = showsInputPreview ? primaryTextColor : secondaryTextColor
        messageView.font = .systemFont(ofSize: 15)
        messageView.backgroundColor = .white
        messageView.layer.cornerRadius = 16
        messageView.layer.borderWidth = showsInputPreview ? 1.5 : 1
        messageView.layer.borderColor = (showsInputPreview
            ? UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
            : UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)).cgColor
        messageView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        messageView.textContainer.lineFragmentPadding = 0
        messageView.keyboardType = .default
        messageView.returnKeyType = .send
        messageView.autocorrectionType = .yes
        messageMinimumHeightConstraint = messageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)
        messageMinimumHeightConstraint.isActive = true
        messageHeightConstraint = messageView.heightAnchor.constraint(equalToConstant: 160)
        messageHeightConstraint.priority = .defaultHigh
        messageHeightConstraint.isActive = true
        messageView.delegate = self
    }

}
