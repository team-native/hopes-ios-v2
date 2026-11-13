import UIKit

final class ChatLocationFailureCardView: UIView {
    init(onSettingsRequested: @escaping () -> Void, onRetryRequested: @escaping () -> Void) {
        super.init(frame: .zero)
        configure(onSettingsRequested: onSettingsRequested, onRetryRequested: onRetryRequested)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(onSettingsRequested: @escaping () -> Void, onRetryRequested: @escaping () -> Void) {
        let alert = UIImageView(image: UIImage(named: "location-failure-alert"))
        alert.contentMode = .scaleAspectFit
        alert.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            alert.widthAnchor.constraint(equalToConstant: 20),
            alert.heightAnchor.constraint(equalToConstant: 20)
        ])

        let title = makeLabel(
            "위치를 확인하지 못했어요",
            fontSize: 15,
            color: UIColor(red: 239 / 255.0, green: 68 / 255.0, blue: 88 / 255.0, alpha: 1),
            lineHeight: 24
        )
        let heading = UIStackView(arrangedSubviews: [alert, title])
        heading.axis = .horizontal
        heading.alignment = .center
        heading.spacing = 8

        let description = makeLabel(
            "위치 서비스가 꺼져 있거나 신호가 약할 수 있어요. 설정을 확인한 뒤 다시 시도해 주세요.",
            fontSize: 14,
            color: LocationMapStyle.secondary,
            lineHeight: 20
        )
        let actions = UIStackView(arrangedSubviews: [
            makeActionButton("설정 열기", action: onSettingsRequested),
            makeActionButton("다시 시도", action: onRetryRequested)
        ])
        actions.axis = .horizontal
        actions.alignment = .leading
        actions.spacing = 8

        let content = UIStackView(arrangedSubviews: [heading, description, actions])
        content.axis = .vertical
        content.spacing = 6
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeLabel(_ text: String, fontSize: CGFloat, color: UIColor, lineHeight: CGFloat) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle(lineHeight: lineHeight)
            ]
        )
        return label
    }

    private func makeActionButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .custom)
        button.setAttributedTitle(
            NSAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: LocationMapStyle.tertiary,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .paragraphStyle: paragraphStyle(lineHeight: 20)
                ]
            ),
            for: .normal
        )
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func paragraphStyle(lineHeight: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        return style
    }
}
