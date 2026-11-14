import UIKit

@MainActor
final class WelcomeChatPreviewView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureContent()
    }

    private func configureContent() {
        let preview = UIStackView()
        preview.axis = .vertical
        preview.spacing = 10
        preview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(preview)
        preview.addArrangedSubview(makeQuestionRow())
        preview.addArrangedSubview(makeAnswerRow())
        preview.addArrangedSubview(makeChipsRow())

        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: centerXAnchor),
            preview.centerYAnchor.constraint(equalTo: centerYAnchor),
            preview.widthAnchor.constraint(equalToConstant: 320),
            preview.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            preview.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }

    private func makeQuestionRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.addArrangedSubview(UIView())

        let question = WelcomePaddedLabel()
        question.text = "기숙사 하루 일과가 어떻게 돼?"
        question.font = .systemFont(ofSize: 14, weight: .medium)
        question.textColor = .white
        question.textAlignment = .center
        question.backgroundColor = WelcomePalette.blue
        question.layer.cornerRadius = 22
        question.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        question.clipsToBounds = true
        question.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)
        question.numberOfLines = 1
        question.setContentHuggingPriority(.required, for: .horizontal)
        row.widthAnchor.constraint(equalToConstant: 320).isActive = true
        row.addArrangedSubview(question)
        return row
    }

    private func makeAnswerRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        row.widthAnchor.constraint(equalToConstant: 320).isActive = true
        row.addArrangedSubview(makeAvatar())
        row.addArrangedSubview(makeAnswerCard())
        return row
    }

    private func makeAvatar() -> UIView {
        let avatar = UIView()
        avatar.backgroundColor = .white
        avatar.layer.cornerRadius = 16
        avatar.layer.borderWidth = 1
        avatar.layer.borderColor = WelcomePalette.border.cgColor
        avatar.layer.shadowColor = WelcomePalette.shadow.cgColor
        avatar.layer.shadowOpacity = 0.05
        avatar.layer.shadowRadius = 4
        avatar.layer.shadowOffset = CGSize(width: 0, height: 2)
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let logoMask = UIView()
        logoMask.clipsToBounds = true
        logoMask.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(logoMask)

        let logo = UIImageView(image: UIImage(named: "auth-start-logo-mark"))
        logo.contentMode = .scaleToFill
        logo.translatesAutoresizingMaskIntoConstraints = false
        logoMask.addSubview(logo)
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),
            logoMask.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            logoMask.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            logoMask.widthAnchor.constraint(equalToConstant: 13),
            logoMask.heightAnchor.constraint(equalToConstant: 20),
            logo.widthAnchor.constraint(equalToConstant: 31),
            logo.heightAnchor.constraint(equalToConstant: 31),
            logo.centerXAnchor.constraint(equalTo: logoMask.centerXAnchor),
            logo.topAnchor.constraint(equalTo: logoMask.topAnchor, constant: -4.5)
        ])
        return avatar
    }

    private func makeAnswerCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        card.layer.borderWidth = 1
        card.layer.borderColor = WelcomePalette.border.cgColor
        card.layer.shadowColor = WelcomePalette.shadow.cgColor
        card.layer.shadowOpacity = 0.09
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let stack = UIStackView(arrangedSubviews: [makeTag(), makeAnswerText()])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        let answerText = stack.arrangedSubviews[1]
        answerText.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        return card
    }

    private func makeTag() -> UILabel {
        let tag = WelcomePaddedLabel()
        tag.text = "10기 선배 경험 기반"
        tag.font = .systemFont(ofSize: 12)
        tag.textColor = WelcomePalette.blue
        tag.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        tag.layer.cornerRadius = 11
        tag.clipsToBounds = true
        tag.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
        tag.setContentHuggingPriority(.required, for: .horizontal)
        return tag
    }

    private func makeAnswerText() -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: "저녁 식사 후 자습, 점호 순서예요.\n일주일이면 루틴이 잡혀요.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: WelcomePalette.ink,
                .paragraphStyle: paragraphStyle(lineHeight: 20)
            ]
        )
        label.numberOfLines = 2
        return label
    }

    private func makeChipsRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.widthAnchor.constraint(equalToConstant: 320).isActive = true
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 0)
        row.addArrangedSubview(makeChip("외출은 어떻게 해?"))
        row.addArrangedSubview(makeChip("준비물 알려줘"))
        row.addArrangedSubview(UIView())
        return row
    }

    private func makeChip(_ title: String) -> UILabel {
        let chip = WelcomePaddedLabel()
        chip.text = title
        chip.font = .systemFont(ofSize: 12)
        chip.textColor = WelcomePalette.secondary
        chip.layer.cornerRadius = 14
        chip.layer.borderWidth = 1
        chip.layer.borderColor = WelcomePalette.border.cgColor
        chip.clipsToBounds = true
        chip.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        chip.setContentHuggingPriority(.required, for: .horizontal)
        return chip
    }

    private func paragraphStyle(lineHeight: CGFloat) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        return paragraph
    }
}

private final class WelcomePaddedLabel: UILabel {
    var contentInsets = NSDirectionalEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.leading,
            bottom: contentInsets.bottom,
            right: contentInsets.trailing
        )))
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insets = UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.leading,
            bottom: contentInsets.bottom,
            right: contentInsets.trailing
        )
        let textBounds = bounds.inset(by: insets)
        let textRect = super.textRect(forBounds: textBounds, limitedToNumberOfLines: numberOfLines)
        let expandedInsets = UIEdgeInsets(
            top: -insets.top,
            left: -insets.left,
            bottom: -insets.bottom,
            right: -insets.right
        )
        return textRect.inset(by: expandedInsets)
    }
}

private enum WelcomePalette {
    static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    static let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    static let border = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    static let shadow = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1)
}
