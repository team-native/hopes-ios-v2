import UIKit

@MainActor
extension HistoryViewController {
    func addHistoryHeading() {
        let title = AppStyle.label("지난 대화", size: 28, weight: .bold, color: AppStyle.ink)
        title.attributedText = NSAttributedString(string: "지난 대화", attributes: [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: AppStyle.ink,
            .kern: -0.4,
            .paragraphStyle: lineStyle(height: 38)
        ])
        title.heightAnchor.constraint(equalToConstant: 38).isActive = true
        let subtitle = AppStyle.label("이전 대화를 이어서 볼 수 있어요.", size: 14, weight: .medium,
            color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1))
        subtitle.attributedText = NSAttributedString(string: "이전 대화를 이어서 볼 수 있어요.", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1),
            .paragraphStyle: lineStyle(height: 20)
        ])
        subtitle.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let heading = UIStackView(arrangedSubviews: [title, subtitle])
        heading.axis = .vertical
        heading.spacing = 4
        contentStack.addArrangedSubview(heading)
    }

    func addEmptyHistoryState() {
        let illustration = makeEmptyHistoryIllustration()

        let title = AppStyle.label("아직 대화가 없어요", size: 18, weight: .medium)
        title.textAlignment = .center
        let subtitle = AppStyle.label("선배에게 첫 질문을 해보세요.", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "채팅 시작하기"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        button.configuration = configuration
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.accessibilityIdentifier = "history-empty-start-chat"
        button.addAction(UIAction { [weak self] _ in
            self?.tabBarController?.selectedIndex = 1
        }, for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [illustration, title, subtitle, button])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12

        let container = UIView()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        contentStack.addArrangedSubview(container)
        container.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor, multiplier: 0.72)
            .isActive = true
    }

    private func makeEmptyHistoryIllustration() -> UIView {
        let illustration = UIView()
        illustration.backgroundColor = .white
        illustration.layer.cornerRadius = 44
        illustration.layer.borderWidth = 1
        illustration.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        illustration.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.10).cgColor
        illustration.layer.shadowOpacity = 1
        illustration.layer.shadowRadius = 14
        illustration.layer.shadowOffset = CGSize(width: 0, height: 8)
        illustration.widthAnchor.constraint(equalToConstant: 88).isActive = true
        illustration.heightAnchor.constraint(equalToConstant: 88).isActive = true
        let icon = UIImageView(image: image(named: "history-empty-chat"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36)
        ])
        return illustration
    }

    func addNewConversationButton() {
        let newConversation = AppStyle.button("새 대화 시작", primary: true) { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        }
        var configuration = UIButton.Configuration.filled()
        configuration.title = "새 대화 시작"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        newConversation.configuration = configuration
        newConversation.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        newConversation.heightAnchor.constraint(equalToConstant: 50).isActive = true
        newConversation.layer.cornerRadius = 12
        newConversation.clipsToBounds = true
        newConversationButton = newConversation
        contentStack.addArrangedSubview(newConversation)
    }

    func lineStyle(height: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = height
        style.maximumLineHeight = height
        return style
    }
}
