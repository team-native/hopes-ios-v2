import UIKit

@MainActor
extension ChatHomeViewController {
    func makeRecommendationSkeleton() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0
        rows.isLayoutMarginsRelativeArrangement = true
        rows.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 17, bottom: 5, trailing: 17)
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            card.heightAnchor.constraint(equalToConstant: 250)
        ])

        for _ in 0..<4 {
            let icon = makeSkeletonBlock(width: 36, height: 36, radius: 12)
            let title = makeSkeletonBlock(width: 220, height: 12, radius: 6)
            let subtitle = makeSkeletonBlock(width: 144, height: 10, radius: 5)
            let labels = UIStackView(arrangedSubviews: [title, subtitle])
            labels.axis = .vertical
            labels.alignment = .leading
            labels.spacing = 8

            let row = UIStackView(arrangedSubviews: [icon, labels])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.heightAnchor.constraint(equalToConstant: 60).isActive = true
            rows.addArrangedSubview(row)
        }
        card.accessibilityLabel = "추천 질문을 불러오는 중"
        card.accessibilityIdentifier = "chat-recommendation-skeleton"
        return card
    }

    private func makeSkeletonBlock(width: CGFloat, height: CGFloat, radius: CGFloat) -> UIView {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false
        block.backgroundColor = UIColor(red: 237 / 255, green: 241 / 255, blue: 247 / 255, alpha: 1)
        block.layer.cornerRadius = radius
        NSLayoutConstraint.activate([
            block.widthAnchor.constraint(equalToConstant: width),
            block.heightAnchor.constraint(equalToConstant: height)
        ])
        AppLoadingMotion.pulse(block)
        return block
    }

    func makeBasicQuestionList() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0
        rows.isLayoutMarginsRelativeArrangement = true
        rows.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 17, bottom: 5, trailing: 17)
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            card.heightAnchor.constraint(equalToConstant: 192)
        ])

        let questions = [
            ("chat-question-bed-icon", "기숙사 하루 일과가 어떻게 돼?"),
            ("chat-question-file-icon", "입학하려면 뭘 준비해야 해?"),
            ("chat-question-heart-icon", "후배한테 해주고 싶은 조언 있어?")
        ]
        for (index, item) in questions.enumerated() {
            rows.addArrangedSubview(makeBasicQuestionRow(iconName: item.0, question: item.1))
            if index < questions.count - 1 {
                let divider = UIView()
                divider.backgroundColor = line
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                rows.addArrangedSubview(divider)
            }
        }
        return card
    }

    private func makeBasicQuestionRow(iconName: String, question: String) -> UIControl {
        let iconChip = makeQuestionIcon(iconName)
        let title = UILabel()
        title.text = question
        title.font = .systemFont(ofSize: 15)
        title.textColor = ink
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let content = UIStackView(arrangedSubviews: [iconChip, title, makeQuestionChevron()])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)

        let row = UIControl()
        row.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: row.topAnchor),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            row.heightAnchor.constraint(equalToConstant: 60)
        ])
        row.accessibilityLabel = question
        row.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(ChatConversationViewController(question: question),
                animated: true)
        }, for: .touchUpInside)
        return row
    }

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
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 13, leading: 17, bottom: 13, trailing: 17)

        let card = UIControl()
        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            card.heightAnchor.constraint(equalToConstant: 62)
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
            self?.fillQuestion(question)
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

        view.keyboardLayoutGuide.usesBottomSafeArea = true
        view.keyboardLayoutGuide.followsUndockedKeyboard = false
        NSLayoutConstraint.activate([
            composerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            composerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            composerBar.heightAnchor.constraint(equalToConstant: 52),
            composerBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10),
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
