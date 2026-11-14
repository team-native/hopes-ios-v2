import UIKit

@MainActor
extension ChatHomeViewController {
    func makeQuestionCard(iconName: String, question: String) -> UIView {
        let iconChip = makeQuestionIcon(iconName)

        let title = UILabel()
        title.text = question
        title.font = .systemFont(ofSize: 15)
        title.textColor = ink
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chevron = makeQuestionChevron()

        let content = UIStackView(arrangedSubviews: [iconChip, title, chevron])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        let card = UIControl()
        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            card.heightAnchor.constraint(equalToConstant: 60)
        ])
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.accessibilityLabel = question
        card.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(ChatConversationViewController(question: question),
                animated: true)
        }, for: .touchUpInside)
        return card
    }

    private func makeQuestionIcon(_ name: String) -> UIView {
        let chip = UIView()
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.backgroundColor = softBlue
        chip.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(named: name))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(icon)
        NSLayoutConstraint.activate([
            chip.widthAnchor.constraint(equalToConstant: 36),
            chip.heightAnchor.constraint(equalToConstant: 36),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            icon.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: chip.centerYAnchor)
        ])
        return chip
    }

    private func makeQuestionChevron() -> UIImageView {
        let chevron = UIImageView(image: UIImage(named: "chat-chevron-icon"))
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chevron.widthAnchor.constraint(equalToConstant: 18),
            chevron.heightAnchor.constraint(equalToConstant: 18)
        ])
        return chevron
    }

    func configureComposer() {
        composerBar.translatesAutoresizingMaskIntoConstraints = false
        composerBar.backgroundColor = .white
        composerBar.layer.cornerRadius = 26
        composerBar.layer.borderWidth = 1
        composerBar.layer.borderColor = line.cgColor
        composerBar.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.09).cgColor
        composerBar.layer.shadowOpacity = 1
        composerBar.layer.shadowRadius = 12
        composerBar.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.addSubview(composerBar)

        let attach = makeAttachmentButton()

        messageField.attributedPlaceholder = NSAttributedString(string: "선배에게 메시지 보내기", attributes: [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: tertiary
        ])
        messageField.font = .systemFont(ofSize: 15)
        messageField.textColor = ink
        messageField.borderStyle = .none
        messageField.returnKeyType = .send
        messageField.delegate = self
        messageField.accessibilityIdentifier = "chat-message-input"
        messageField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let mic = makeVoiceInputButton()
        let send = makeSendButton()

        let controls = UIStackView(arrangedSubviews: [attach, messageField, mic, send])
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 2
        controls.isLayoutMarginsRelativeArrangement = true
        controls.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        controls.translatesAutoresizingMaskIntoConstraints = false
        composerBar.addSubview(controls)

        NSLayoutConstraint.activate([
            composerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            composerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            composerBar.heightAnchor.constraint(equalToConstant: 52),
            composerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            controls.topAnchor.constraint(equalTo: composerBar.topAnchor),
            controls.leadingAnchor.constraint(equalTo: composerBar.leadingAnchor),
            controls.trailingAnchor.constraint(equalTo: composerBar.trailingAnchor),
            controls.bottomAnchor.constraint(equalTo: composerBar.bottomAnchor)
        ])
    }

    private func makeAttachmentButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "chat-plus-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = line.cgColor
        button.accessibilityLabel = "첨부"
        button.accessibilityIdentifier = "chat-attach"
        button.addTarget(self, action: #selector(openAttachmentPicker), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    private func makeVoiceInputButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "chat-mic-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = "음성 입력"
        button.addTarget(self, action: #selector(showVoiceInputNotice), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    private func makeSendButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = brandBlue
        button.layer.cornerRadius = 20
        button.setImage(UIImage(named: "chat-send-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = "메시지 보내기"
        button.accessibilityIdentifier = "chat-send-message"
        button.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

}
