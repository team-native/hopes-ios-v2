import UIKit

@MainActor
extension ChatConversationViewController {
    func addConversationHeader() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppStyle.ink
        back.widthAnchor.constraint(equalToConstant: 44).isActive = true
        back.heightAnchor.constraint(equalToConstant: 44).isActive = true
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) },
            for: .touchUpInside)

        let department = UserDefaults.standard.string(forKey: "chat.selectedDepartment")
            .flatMap { $0.isEmpty ? nil : $0 } ?? "소프트웨어개발과"
        let major = UserDefaults.standard.string(forKey: "chat.selectedMajor")
            .flatMap { $0.isEmpty ? nil : $0 } ?? "Frontend"
        let context = AppStyle.label("\(department) · \(major)", size: 12, color: AppStyle.muted)
        let title = AppStyle.label("전공 공부", size: 18, weight: .medium, color: ChatDetailPalette.ink)
        applyLineHeight(title, lineHeight: 26, height: 26)
        context.textColor = ChatDetailPalette.muted
        applyLineHeight(context, lineHeight: 16, height: 16)
        let titleStack = UIStackView(arrangedSubviews: [title, context])
        titleStack.axis = .vertical
        titleStack.spacing = 0
        let location = makeLocationActionButton()
        let row = UIStackView(arrangedSubviews: [back, titleStack, location])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.setCustomSpacing(0, after: titleStack)
        messagesStack.addArrangedSubview(row)
    }

    func addUserMessage(_ text: String) {
        let bubble = UIView()
        bubble.backgroundColor = AppStyle.blue
        bubble.layer.cornerRadius = 20
        bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        bubble.layer.shadowColor = UIColor(red: 46 / 255, green: 135 / 255, blue: 245 / 255, alpha: 0.2).cgColor
        bubble.layer.shadowOpacity = 1
        bubble.layer.shadowRadius = 10
        bubble.layer.shadowOffset = CGSize(width: 0, height: 8)
        bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 340).isActive = true
        let label = AppStyle.label(text, size: 15, color: .white)
        applyLineHeight(label, lineHeight: 24, height: 24)
        let wrapper = UIView()
        wrapper.addSubview(bubble)
        bubble.addSubview(label)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: wrapper.topAnchor),
            bubble.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            bubble.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -12)
        ])
        messagesStack.addArrangedSubview(wrapper)
    }

    func addFormattedAnswer() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.heightAnchor.constraint(equalToConstant: 380).isActive = true
        card.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        card.layer.borderColor = ChatDetailPalette.border.cgColor
        let title = AppStyle.label("Frontend 시작 순서", size: 18, weight: .medium, color: ChatDetailPalette.ink)
        applyLineHeight(title, lineHeight: 26, height: 26)
        let intro = AppStyle.label("처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요.", size: 15,
            color: ChatDetailPalette.ink)
        applyLineHeight(intro, lineHeight: 24, height: 48)
        let answer = UIStackView(arrangedSubviews: [
            title,
            intro,
            makeAnswerSteps(),
            makeCodeCard(),
            makeAnswerQuote(),
            makeSchoolLink()
        ])
        answer.axis = .vertical
        answer.spacing = 10
        answer.isLayoutMarginsRelativeArrangement = true
        answer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        answer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(answer)
        NSLayoutConstraint.activate([
            answer.topAnchor.constraint(equalTo: card.topAnchor),
            answer.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            answer.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            answer.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
        addAnswerActions()
        addRelatedQuestions()
    }

    private func makeAnswerSteps() -> UIStackView {
        let steps = UIStackView()
        steps.axis = .vertical
        steps.spacing = 4
        let titles = ["HTML·CSS로 간단한 페이지 만들기", "JavaScript 기초 문법 익히기", "React로 작은 프로젝트 완성하기"]
        for (index, text) in titles.enumerated() {
            let number = AppStyle.label("\(index + 1).", size: 15, weight: .medium, color: ChatDetailPalette.brand)
            number.widthAnchor.constraint(equalToConstant: index == 0 ? 12 : 14).isActive = true
            applyLineHeight(number, lineHeight: 24, height: 24)
            let body = AppStyle.label(text, size: 15, color: ChatDetailPalette.ink)
            applyLineHeight(body, lineHeight: 24, height: 24)
            let row = UIStackView(arrangedSubviews: [number, body])
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 8
            steps.addArrangedSubview(row)
        }
        steps.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return steps
    }

    private func makeCodeCard() -> UIView {
        let codeCard = UIView()
        codeCard.backgroundColor = AppStyle.canvas
        codeCard.layer.cornerRadius = 12
        codeCard.layer.borderWidth = 1
        codeCard.layer.borderColor = AppStyle.line.cgColor
        codeCard.heightAnchor.constraint(equalToConstant: 98).isActive = true
        let language = AppStyle.label("html", size: 12, color: AppStyle.muted)
        let copy = UIButton(type: .system)
        copy.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copy.tintColor = AppStyle.muted
        copy.accessibilityLabel = "코드 복사"
        copy.addAction(UIAction { [weak self] _ in
            UIPasteboard.general.string = "<button class=\"primary\">\n  질문하기\n</button>"
            self?.showToast("코드를 복사했어요")
        }, for: .touchUpInside)
        copy.widthAnchor.constraint(equalToConstant: 28).isActive = true
        copy.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let codeHeader = UIStackView(arrangedSubviews: [language, copy])
        codeHeader.axis = .horizontal
        codeHeader.alignment = .center
        let code = AppStyle.label("<button class=\"primary\">\n  질문하기\n</button>", size: 12)
        code.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        let codeStack = UIStackView(arrangedSubviews: [codeHeader, code])
        codeStack.axis = .vertical
        codeStack.spacing = 6
        codeStack.isLayoutMarginsRelativeArrangement = true
        codeStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        codeStack.translatesAutoresizingMaskIntoConstraints = false
        codeCard.addSubview(codeStack)
        NSLayoutConstraint.activate([
            codeStack.topAnchor.constraint(equalTo: codeCard.topAnchor),
            codeStack.leadingAnchor.constraint(equalTo: codeCard.leadingAnchor),
            codeStack.trailingAnchor.constraint(equalTo: codeCard.trailingAnchor),
            codeStack.bottomAnchor.constraint(equalTo: codeCard.bottomAnchor)
        ])
        return codeCard
    }

    private func makeAnswerQuote() -> UIView {
        let quote = AppStyle.label("막히면 선배에게 바로 물어보는 게 제일 빨라요.", size: 14, weight: .medium,
            color: ChatDetailPalette.muted)
        applyLineHeight(quote, lineHeight: 20, height: 20)
        let quoteRow = UIView()
        let quoteLine = UIView()
        quoteLine.backgroundColor = AppStyle.blue.withAlphaComponent(0.45)
        quoteRow.addSubview(quoteLine)
        quoteRow.addSubview(quote)
        quoteLine.translatesAutoresizingMaskIntoConstraints = false
        quote.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quoteLine.leadingAnchor.constraint(equalTo: quoteRow.leadingAnchor),
            quoteLine.topAnchor.constraint(equalTo: quoteRow.topAnchor),
            quoteLine.bottomAnchor.constraint(equalTo: quoteRow.bottomAnchor),
            quoteLine.widthAnchor.constraint(equalToConstant: 3),
            quote.leadingAnchor.constraint(equalTo: quoteLine.trailingAnchor, constant: 10),
            quote.trailingAnchor.constraint(equalTo: quoteRow.trailingAnchor),
            quote.topAnchor.constraint(equalTo: quoteRow.topAnchor, constant: 2),
            quote.bottomAnchor.constraint(equalTo: quoteRow.bottomAnchor, constant: -2)
        ])
        return quoteRow
    }

    private func makeSchoolLink() -> UIButton {
        let schoolLink = UIButton(type: .system)
        schoolLink.setAttributedTitle(NSAttributedString(string: "학교 전공 소개 페이지 보기", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: ChatDetailPalette.brand,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]), for: .normal)
        schoolLink.heightAnchor.constraint(equalToConstant: 20).isActive = true
        schoolLink.contentHorizontalAlignment = .leading
        schoolLink.addAction(UIAction { [weak self] _ in
            self?.presentMessage("전공 소개 페이지는 서비스 연결 후 열 수 있어요")
        }, for: .touchUpInside)
        return schoolLink
    }

    func addAnswerActions() {
        let like = actionChip("좋아요", width: 73, selected: isLiked) { [weak self] in
            guard let self else { return }
            self.isLiked.toggle()
            self.refreshAnswerActions()
        }
        like.accessibilityIdentifier = "answer-like"
        let more = actionChip("더 물어보기", width: 100, selected: true) { [weak self] in
            self?.inputField.becomeFirstResponder()
        }
        let share = actionChip("공유", width: 60) { [weak self] in self?.shareAnswer() }
        let trailingSpace = UIView()
        trailingSpace.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [like, more, share, trailingSpace])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        messagesStack.addArrangedSubview(row)
    }

    func refreshAnswerActions() {
        let row = messagesStack.arrangedSubviews.first { view in
            (view as? UIStackView)?.arrangedSubviews.first?.accessibilityIdentifier == "answer-like"
        } as? UIStackView
        guard let row, let like = row.arrangedSubviews.first as? UIButton else { return }
        var configuration = like.configuration ?? UIButton.Configuration.plain()
        configuration.baseForegroundColor = isLiked ? .white : ChatDetailPalette.ink
        configuration.background.backgroundColor = isLiked ? ChatDetailPalette.brand : .white
        configuration.background.strokeColor = isLiked ? .clear : ChatDetailPalette.border
        configuration.background.strokeWidth = isLiked ? 0 : 1
        like.configuration = configuration
    }

    func actionChip(_ title: String, width: CGFloat, selected: Bool = false, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(selected ? .white : ChatDetailPalette.ink, for: .normal)
        button.backgroundColor = selected ? ChatDetailPalette.brand : .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = ChatDetailPalette.border.cgColor
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        configuration.baseForegroundColor = selected ? .white : ChatDetailPalette.ink
        configuration.background.backgroundColor = selected ? ChatDetailPalette.brand : .white
        configuration.background.strokeColor = selected ? .clear : ChatDetailPalette.border
        configuration.background.strokeWidth = selected ? 0 : 1
        configuration.background.cornerRadius = 20
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        button.configuration = configuration
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    func addRelatedQuestions() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.borderColor = ChatDetailPalette.border.cgColor
        card.layer.shadowColor = ChatDetailPalette.shadow.cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        let heading = AppStyle.label("추가로 많이 묻는 질문", size: 16, weight: .bold, color: ChatDetailPalette.ink)
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 4
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 17, leading: 17, bottom: 9, trailing: 17)
        applyLineHeight(heading, lineHeight: 24, height: 24)
        content.addArrangedSubview(heading)
        let questions = ["포트폴리오는 언제부터 만들었어?", "전공 동아리 들어가려면 뭐 준비해?"]
        for (index, question) in questions.enumerated() {
            content.addArrangedSubview(makeRelatedQuestionButton(question))
            if index < questions.count - 1 {
                let divider = UIView()
                divider.backgroundColor = ChatDetailPalette.border
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                content.addArrangedSubview(divider)
            }
        }
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
    }

    private func makeRelatedQuestionButton(_ question: String) -> UIButton {
        let button = UIButton(type: .system)
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = ChatDetailPalette.brand
        check.contentMode = .scaleAspectFit
        check.widthAnchor.constraint(equalToConstant: 18).isActive = true
        check.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let title = AppStyle.label(question, size: 15, color: ChatDetailPalette.ink)
        applyLineHeight(title, lineHeight: 24, height: 24)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = ChatDetailPalette.muted
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 20).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 20).isActive = true

        row.addArrangedSubview(check)
        row.addArrangedSubview(title)
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(chevron)
        row.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.accessibilityLabel = question
        button.addAction(UIAction { [weak self] _ in
            self?.addUserMessage(question)
            self?.addMessage("질문을 기록했어요. 실제 답변은 서버 연결 후 표시됩니다.", outgoing: false)
        }, for: .touchUpInside)
        return button
    }
    func applyLineHeight(_ label: UILabel, lineHeight: CGFloat, height: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        label.attributedText = NSAttributedString(string: label.text ?? "", attributes: [
            .font: label.font as Any,
            .foregroundColor: label.textColor as Any,
            .paragraphStyle: paragraph
        ])
        label.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
