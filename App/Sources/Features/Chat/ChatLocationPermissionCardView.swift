import UIKit

final class ChatLocationPermissionCardView: UIView {
    init(onLater: @escaping () -> Void, onAllow: @escaping () -> Void) {
        super.init(frame: .zero)
        configure(onLater: onLater, onAllow: onAllow)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(onLater: @escaping () -> Void, onAllow: @escaping () -> Void) {
        configureCardStyle()
        let header = makeHeader()
        let actions = makeActions(onLater: onLater, onAllow: onAllow)

        let content = UIStackView(arrangedSubviews: [header, actions])
        content.axis = .vertical
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureCardStyle() {
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        layer.shadowColor = UIColor(
            red: 26 / 255.0,
            green: 64 / 255.0,
            blue: 128 / 255.0,
            alpha: 0.05
        ).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    private func makeHeader() -> UIStackView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = LocationMapStyle.brandSoft
        iconContainer.layer.cornerRadius = 12
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44)
        ])
        let icon = UIImageView(image: UIImage(named: "map-pin-blue"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        let title = AppStyle.label("위치 권한이 필요해요", size: 15, weight: .medium, color: LocationMapStyle.ink)
        title.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let subtitle = AppStyle.label(
            "현재 위치는 답변에만 쓰고 저장하지 않아요.",
            size: 12,
            color: LocationMapStyle.secondary
        )
        subtitle.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let text = UIStackView(arrangedSubviews: [title, subtitle])
        text.axis = .vertical
        text.spacing = 2
        let header = UIStackView(arrangedSubviews: [iconContainer, text])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        return header
    }

    private func makeActions(onLater: @escaping () -> Void, onAllow: @escaping () -> Void) -> UIStackView {
        let actions = UIStackView(arrangedSubviews: [
            makeLaterButton(action: onLater),
            makeAllowButton(action: onAllow)
        ])
        actions.axis = .horizontal
        actions.spacing = 8
        actions.distribution = .fillEqually
        return actions
    }

    private func makeLaterButton(action: @escaping () -> Void) -> UIButton {
        let button = makeButton(title: "나중에", background: .white, foreground: LocationMapStyle.brand, action: action)
        button.layer.borderWidth = 1
        button.layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        return button
    }

    private func makeAllowButton(action: @escaping () -> Void) -> UIButton {
        makeButton(title: "위치 허용", background: LocationMapStyle.brand, foreground: .white, action: action)
    }

    private func makeButton(
        title: String,
        background: UIColor,
        foreground: UIColor,
        action: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = background
        configuration.baseForegroundColor = foreground
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
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}
