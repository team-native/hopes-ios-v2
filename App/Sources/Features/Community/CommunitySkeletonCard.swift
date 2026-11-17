import UIKit

@MainActor
extension CommunityViewController {
    static func makeSkeletonCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22
        card.accessibilityIdentifier = "community-skeleton-card"
        let bars: [(CGFloat, CGFloat)] = [(48, 20), (240, 14), (300, 12), (200, 12)]
        let stack = UIStackView(arrangedSubviews: bars.map { width, height in
            let bar = UIView()
            bar.backgroundColor = UIColor(red: 237 / 255, green: 241 / 255, blue: 247 / 255, alpha: 1)
            bar.layer.cornerRadius = height / 2
            bar.widthAnchor.constraint(equalToConstant: width).isActive = true
            bar.heightAnchor.constraint(equalToConstant: height).isActive = true
            AppLoadingMotion.pulse(bar)
            return bar
        })
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }
}
