import UIKit

final class ChatLocationOutsideSchoolCardView: UIView {
    init(distance: String, onMapRequested: @escaping () -> Void) {
        super.init(frame: .zero)
        configure(distance: distance, onMapRequested: onMapRequested)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(distance: String, onMapRequested: @escaping () -> Void) {
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.05).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let content = UIStackView(arrangedSubviews: [
            AppStyle.label("지금은 학교에서 약 \(distance) 떨어진 곳에 있어요.", size: 15, color: LocationMapStyle.ink),
            makeInfoBanner(),
            makeMapButton(onMapRequested: onMapRequested)
        ])
        content.axis = .vertical
        content.spacing = 10
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

    private func makeInfoBanner() -> UIStackView {
        let icon = UIImageView(image: UIImage(named: "location-outside-info"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16)
        ])
        let text = AppStyle.label("학교 안에서는 건물 기준으로 더 자세히 안내해 드려요.", size: 12, color: LocationMapStyle.secondary)
        let banner = UIStackView(arrangedSubviews: [icon, text])
        banner.axis = .horizontal
        banner.alignment = .center
        banner.spacing = 8
        banner.isLayoutMarginsRelativeArrangement = true
        banner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        banner.backgroundColor = LocationMapStyle.brandSoft
        banner.layer.cornerRadius = 16
        return banner
    }

    private func makeMapButton(onMapRequested: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "지도 보기"
        configuration.baseBackgroundColor = LocationMapStyle.brandSoft
        configuration.baseForegroundColor = LocationMapStyle.brand
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
        button.addAction(UIAction { _ in onMapRequested() }, for: .touchUpInside)
        return button
    }
}
