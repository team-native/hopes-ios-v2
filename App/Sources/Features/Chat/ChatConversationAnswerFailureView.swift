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
        headline.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let detail = AppStyle.label("일시적인 오류예요. 같은 질문으로 다시 시도할 수 있어요.", size: 14, weight: .medium,
            color: AppStyle.muted)
        detail.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let retry = UIButton(type: .system)
        retry.setTitle("다시 시도", for: .normal)
        retry.setTitleColor(AppStyle.muted, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
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
