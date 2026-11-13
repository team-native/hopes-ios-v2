import UIKit

@MainActor
enum HomeHeroFactory {
    static func configureSurface(card: UIView, clipView: UIView, gradient: CAGradientLayer, borderColor: UIColor) {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 245 / 255, green: 249 / 255, blue: 1, alpha: 1)
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.layer.cornerRadius = 24
        clipView.layer.borderWidth = 1
        clipView.layer.borderColor = borderColor.cgColor
        clipView.clipsToBounds = true
        card.addSubview(clipView)
        gradient.colors = [
            UIColor(red: 251 / 255, green: 253 / 255, blue: 1, alpha: 1).cgColor,
            UIColor(red: 238 / 255, green: 244 / 255, blue: 254 / 255, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        clipView.layer.insertSublayer(gradient, at: 0)
        card.heightAnchor.constraint(equalToConstant: 176).isActive = true
        NSLayoutConstraint.activate([
            clipView.topAnchor.constraint(equalTo: card.topAnchor),
            clipView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            clipView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            clipView.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    static func chatStartButton(blue: UIColor, softBlue: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = "채팅 시작하기"
        configuration.baseForegroundColor = blue
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.background.backgroundColor = softBlue
        configuration.background.cornerRadius = 10
        button.configuration = configuration
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        button.accessibilityIdentifier = "home-start-chat"
        return button
    }
}

@MainActor
enum HomeTipRowFactory {
    static func make(number: String, caption: String, text: String, blue: UIColor, softBlue: UIColor) -> UIView {
        let badge = UILabel()
        badge.text = number
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 14, weight: .medium)
        badge.textColor = blue
        badge.backgroundColor = softBlue
        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28)
        ])

        let copy = UIStackView(arrangedSubviews: [
            HomePreviewStateViews.label(caption, size: 12, color: AppStyle.muted, lineHeight: 16),
            HomePreviewStateViews.label(
                text,
                size: 15,
                weight: .medium,
                color: AppStyle.ink,
                lineHeight: 24,
                kern: -0.1
            )
        ])
        copy.axis = .vertical
        copy.spacing = 2
        let row = UIStackView(arrangedSubviews: [badge, copy])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        row.backgroundColor = .white
        row.layer.cornerRadius = 20
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        row.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        row.layer.shadowOpacity = 1
        row.layer.shadowRadius = 8
        row.layer.shadowOffset = CGSize(width: 0, height: 4)
        return row
    }
}
