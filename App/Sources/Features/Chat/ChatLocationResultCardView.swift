import CoreLocation
import UIKit

final class ChatLocationResultCardView: UIView {
    init(accuracy: CLLocationAccuracy, onMapRequested: @escaping () -> Void) {
        super.init(frame: .zero)
        configure(accuracy: accuracy, onMapRequested: onMapRequested)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(accuracy: CLLocationAccuracy, onMapRequested: @escaping () -> Void) {
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.05).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(AppStyle.label("지금 학교 본관 근처에 있어요.", size: 15, color: LocationMapStyle.ink))
        content.addArrangedSubview(makeMapPreview())
        content.addArrangedSubview(makeLocationDetails(accuracy: accuracy))
        content.addArrangedSubview(makeMapButton(onMapRequested: onMapRequested))
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeMapPreview() -> UIView {
        let map = LocationMapIllustrationView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.heightAnchor.constraint(equalToConstant: 130).isActive = true
        return map
    }

    private func makeLocationDetails(accuracy: CLLocationAccuracy) -> UIStackView {
        let title = AppStyle.label("광주소프트웨어마이스터고 · 본관 부근", size: 14, weight: .medium, color: LocationMapStyle.ink)
        let details = AppStyle.label(
            "정확도 약 ±\(Int(accuracy.rounded()))m · 방금 측정",
            size: 12,
            color: LocationMapStyle.secondary
        )
        let stack = UIStackView(arrangedSubviews: [title, details])
        stack.axis = .vertical
        stack.spacing = 2
        return stack
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
