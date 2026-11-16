import UIKit

@MainActor
extension ChatConversationViewController {
    func addAnswerFailure() {
        let danger = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        let card = UIView()
        let alertIcon = UIImageView(image: UIImage(named: "ChatAnswerFailureAlert")?.withRenderingMode(.alwaysOriginal))
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let heading = AppStyle.label("답변을 만들지 못했어요", size: 15, weight: .medium, color: danger)
        heading.attributedText = NSAttributedString(string: "답변을 만들지 못했어요", attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: danger,
            .kern: -0.1
        ])
        let headline = UIStackView(arrangedSubviews: [alertIcon, heading])
        headline.axis = .horizontal
        headline.alignment = .center
        headline.spacing = 8
        headline.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let detail = AppStyle.label("일시적인 오류예요. 같은 질문으로 다시 시도할 수 있어요.", size: 14, weight: .medium,
            color: AppStyle.muted)
        detail.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let retry = UIButton(type: .system)
        retry.setAttributedTitle(NSAttributedString(string: "다시 시도", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]), for: .normal)
        retry.heightAnchor.constraint(equalToConstant: 20).isActive = true
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
}
