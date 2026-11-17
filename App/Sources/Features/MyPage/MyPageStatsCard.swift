import UIKit

@MainActor
extension MyPageViewController {
    func addStatsCard() {
        let card = makeCard(cornerRadius: 24, shadowRadius: 10, shadowYOffset: 4)
        let stats = UIStackView()
        stats.axis = .horizontal
        stats.alignment = .center
        stats.distribution = .fill
        stats.translatesAutoresizingMaskIntoConstraints = false
        let targets = [CommunityPostStore.shared.myPosts.count, CommunityPostStore.shared.myComments.count, chatCount]
        let starts = displayedStatValues
        var statColumns: [UIView] = []
        var valueLabels: [UILabel] = []
        for (index, title) in ["작성글", "댓글", "대화"].enumerated() {
            if index > 0 { stats.addArrangedSubview(makeStatDivider()) }
            let number = styledLabel("\(starts[index])", size: 22, weight: .bold, color: ink, lineHeight: 30,
                kern: -0.3)
            number.accessibilityIdentifier = "mypage-stat-\(index)"
            valueLabels.append(number)
            let caption = styledLabel(title, size: 12, color: secondary, lineHeight: 16)
            let item = UIStackView(arrangedSubviews: [number, caption])
            item.axis = .vertical
            item.alignment = .center
            item.spacing = 2
            stats.addArrangedSubview(item)
            statColumns.append(item)
        }
        NSLayoutConstraint.activate([
            statColumns[0].widthAnchor.constraint(equalTo: statColumns[1].widthAnchor),
            statColumns[1].widthAnchor.constraint(equalTo: statColumns[2].widthAnchor)
        ])
        card.addSubview(stats)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            stats.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stats.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            stats.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            stats.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        replaceStatsCard(with: card)
        for (label, (start, target)) in zip(valueLabels, zip(starts, targets)) {
            AppCountUpAnimator.animate(label, from: start, to: target)
        }
        displayedStatValues = targets
    }

    private func makeStatDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = line
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return divider
    }

    private func replaceStatsCard(with card: UIView) {
        if let old = statsCardView, let index = contentStack.arrangedSubviews.firstIndex(of: old) {
            contentStack.removeArrangedSubview(old)
            old.removeFromSuperview()
            contentStack.insertArrangedSubview(card, at: index)
        } else {
            contentStack.addArrangedSubview(card)
        }
        statsCardView = card
    }
}
