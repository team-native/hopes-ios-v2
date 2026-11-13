import UIKit

@MainActor
extension ChatConversationViewController {
    func addAnswerFailure() {
        let card = UIView()
        let alertIcon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        alertIcon.tintColor = UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1)
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let heading = AppStyle.label("답변을 만들지 못했어요", size: 15, weight: .semibold, color: UIColor(red: 0.94,
            green: 0.27, blue: 0.35, alpha: 1))
        let headline = UIStackView(arrangedSubviews: [alertIcon, heading])
        headline.axis = .horizontal
        headline.alignment = .center
        headline.spacing = 8
        let detail = AppStyle.label("일시적인 오류예요. 같은 질문으로 다시 시도할 수 있어요.", size: 14, weight: .medium,
            color: AppStyle.muted)
        let retry = UIButton(type: .system)
        retry.setTitle("다시 시도", for: .normal)
        retry.setTitleColor(AppStyle.muted, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        retry.contentHorizontalAlignment = .leading
        retry.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.messagesStack.removeArrangedSubview(card)
            card.removeFromSuperview()
            self.answerFailureCard = nil
            self.beginAnswerGeneration()
        }, for: .touchUpInside)
        let content = UIStackView(arrangedSubviews: [headline, detail, retry])
        content.axis = .vertical
        content.spacing = 6
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
        answerFailureCard = card
    }

    func addConversationHeader() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppStyle.ink
        back.widthAnchor.constraint(equalToConstant: 44).isActive = true
        back.heightAnchor.constraint(equalToConstant: 44).isActive = true
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) },
            for: .touchUpInside)

        let department = UserDefaults.standard.string(forKey: "chat.selectedDepartment") ?? "소프트웨어개발과"
        let major = UserDefaults.standard.string(forKey: "chat.selectedMajor") ?? "Frontend"
        let context = AppStyle.label("\(department) · \(major)", size: 12, color: AppStyle.muted)
        let titleStack = UIStackView(arrangedSubviews: [
            AppStyle.label("전공 공부", size: 18, weight: .semibold),
            context
        ])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        let row = UIStackView(arrangedSubviews: [back, titleStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        messagesStack.addArrangedSubview(row)
    }

    func addUserMessage(_ text: String) {
        let bubble = UIView()
        bubble.backgroundColor = AppStyle.blue
        bubble.layer.cornerRadius = 20
        bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 340).isActive = true
        let label = AppStyle.label(text, size: 15, color: .white)
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
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("Frontend 시작 순서", size: 18, weight: .semibold)
        let intro = AppStyle.label("처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요.", size: 15)
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
            let number = AppStyle.label("\(index + 1).", size: 15, weight: .semibold, color: AppStyle.blue)
            number.widthAnchor.constraint(equalToConstant: 22).isActive = true
            let row = UIStackView(arrangedSubviews: [number, AppStyle.label(text, size: 15)])
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 8
            steps.addArrangedSubview(row)
        }
        return steps
    }

    private func makeCodeCard() -> UIView {
        let codeCard = UIView()
        codeCard.backgroundColor = AppStyle.canvas
        codeCard.layer.cornerRadius = 12
        codeCard.layer.borderWidth = 1
        codeCard.layer.borderColor = AppStyle.line.cgColor
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
        let quote = AppStyle.label("막히면 선배에게 바로 물어보는 게 제일 빨라요.", size: 14, weight: .medium, color: AppStyle.muted)
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
        schoolLink.setTitle("학교 전공 소개 페이지 보기", for: .normal)
        schoolLink.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        schoolLink.contentHorizontalAlignment = .leading
        schoolLink.addAction(UIAction { [weak self] _ in
            self?.presentMessage("전공 소개 페이지는 서비스 연결 후 열 수 있어요")
        }, for: .touchUpInside)
        return schoolLink
    }

    func addAnswerActions() {
        let like = actionChip("좋아요", symbol: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
            selected: isLiked) { [weak self] in
            guard let self else { return }
            self.isLiked.toggle()
            self.refreshAnswerActions()
        }
        like.accessibilityIdentifier = "answer-like"
        let more = actionChip("더 물어보기", symbol: "bubble.left", selected: true) { [weak self] in
            self?.inputField.becomeFirstResponder()
        }
        let share = actionChip("공유", symbol: "square.and.arrow.up") { [weak self] in self?.shareAnswer() }
        let row = UIStackView(arrangedSubviews: [like, more, share])
        row.axis = .horizontal
        row.spacing = 8
        messagesStack.addArrangedSubview(row)
    }

    func refreshAnswerActions() {
        let row = messagesStack.arrangedSubviews.first { view in
            (view as? UIStackView)?.arrangedSubviews.first?.accessibilityIdentifier == "answer-like"
        } as? UIStackView
        guard let row, let like = row.arrangedSubviews.first as? UIButton else { return }
        let title = isLiked ? "좋아요 · 1" : "좋아요"
        like.setTitle(title, for: .normal)
        like.setImage(UIImage(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"), for: .normal)
        like.backgroundColor = isLiked ? AppStyle.blue : .white
        like.setTitleColor(isLiked ? .white : AppStyle.ink, for: .normal)
        like.tintColor = isLiked ? .white : AppStyle.ink
    }

    func actionChip(_ title: String, symbol: String, selected: Bool = false, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = selected ? .white : AppStyle.ink
        button.setTitleColor(selected ? .white : AppStyle.ink, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = selected ? AppStyle.blue : .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = AppStyle.line.cgColor
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        button.configuration = configuration
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    func addRelatedQuestions() {
        let card = AppStyle.card()
        let heading = AppStyle.label("추가로 많이 묻는 질문", size: 16, weight: .bold)
        let rows = UIStackView()
        rows.axis = .vertical
        ["포트폴리오는 언제부터 만들었어?", "전공 동아리 들어가려면 뭐 준비해?"].forEach { question in
            let button = UIButton(type: .system)
            button.setTitle("◉  \(question)", for: .normal)
            button.setTitleColor(AppStyle.ink, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15)
            button.contentHorizontalAlignment = .leading
            button.heightAnchor.constraint(equalToConstant: 48).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.addUserMessage(question)
                self?.addMessage("질문을 기록했어요. 실제 답변은 서버 연결 후 표시됩니다.", outgoing: false)
            }, for: .touchUpInside)
            rows.addArrangedSubview(button)
        }
        let content = UIStackView(arrangedSubviews: [heading, rows])
        content.axis = .vertical
        content.spacing = 4
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
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

}
