import UIKit

struct HomePopularRowStyle {
    let blue: UIColor
    let softBlue: UIColor
    let tertiary: UIColor
    let border: UIColor
}

@MainActor
enum HomePopularRowFactory {
    static func make(
        cohort: String,
        title: String,
        likes: String,
        style: HomePopularRowStyle,
        action: @escaping () -> Void
    ) -> UIView {
        let row = UIStackView(arrangedSubviews: [
            makeBadge(cohort, style: style),
            makeTitle(title),
            makeStats(likes, style: style)
        ])
        configure(row, style: style)
        let button = UIButton(type: .custom)
        row.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private static func makeBadge(_ title: String, style: HomePopularRowStyle) -> UILabel {
        let badge = UILabel()
        badge.text = title
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 12)
        badge.textColor = style.blue
        badge.backgroundColor = style.softBlue
        badge.layer.cornerRadius = 11
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.heightAnchor.constraint(equalToConstant: 24),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: title == "전체" ? 43 : 38)
        ])
        return badge
    }

    private static func makeTitle(_ text: String) -> UILabel {
        let title = HomePreviewStateViews.label(text, size: 15, color: AppStyle.ink, lineHeight: 24, kern: -0.1)
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return title
    }

    private static func makeStats(_ likes: String, style: HomePopularRowStyle) -> UIView {
        let heart = UIImageView(image: UIImage(named: "home-like-icon"))
        heart.contentMode = .scaleAspectFit
        heart.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heart.widthAnchor.constraint(equalToConstant: 14),
            heart.heightAnchor.constraint(equalToConstant: 14)
        ])
        let count = HomePreviewStateViews.label(likes, size: 12, color: style.tertiary, lineHeight: 16)
        let stats = UIStackView(arrangedSubviews: [heart, count])
        stats.axis = .horizontal
        stats.alignment = .center
        stats.spacing = 4
        return stats
    }

    private static func configure(_ row: UIStackView, style: HomePopularRowStyle) {
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        row.backgroundColor = .white
        row.layer.cornerRadius = 20
        row.layer.borderWidth = 1
        row.layer.borderColor = style.border.cgColor
        row.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        row.layer.shadowOpacity = 1
        row.layer.shadowRadius = 8
        row.layer.shadowOffset = CGSize(width: 0, height: 4)
    }
}

@MainActor
enum HomeLoadingHeaderFactory {
    static func make(borderColor: UIColor, action: @escaping () -> Void) -> UIView {
        let spacer = UIView()
        let notification = HomePreviewStateViews.notificationButton(borderColor: borderColor, action: action)
        let header = UIStackView(arrangedSubviews: [spacer, notification])
        header.axis = .horizontal
        header.alignment = .center
        return header
    }
}
