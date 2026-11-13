import UIKit

enum LocationMapStyle {
    static let canvas = UIColor(red: 246 / 255.0, green: 249 / 255.0, blue: 252 / 255.0, alpha: 1)
    static let brand = UIColor(red: 47 / 255.0, green: 134 / 255.0, blue: 245 / 255.0, alpha: 1)
    static let brandSoft = UIColor(red: 230 / 255.0, green: 241 / 255.0, blue: 254 / 255.0, alpha: 1)
    static let ink = UIColor(red: 20 / 255.0, green: 27 / 255.0, blue: 43 / 255.0, alpha: 1)
    static let secondary = UIColor(red: 107 / 255.0, green: 120 / 255.0, blue: 144 / 255.0, alpha: 1)
    static let tertiary = UIColor(red: 152 / 255.0, green: 163 / 255.0, blue: 184 / 255.0, alpha: 1)
    static let border = UIColor(red: 220 / 255.0, green: 230 / 255.0, blue: 244 / 255.0, alpha: 1)
    static let subtleBorder = UIColor(red: 235 / 255.0, green: 241 / 255.0, blue: 250 / 255.0, alpha: 1)
}

final class LocationMapIllustrationView: UIView {
    private struct Building {
        let positionX: CGFloat
        let positionY: CGFloat
        let width: CGFloat
        let height: CGFloat
    }

    private let buildings = [
        Building(positionX: 16, positionY: 14, width: 90, height: 44),
        Building(positionX: 124, positionY: 8, width: 70, height: 60),
        Building(positionX: 214, positionY: 22, width: 110, height: 40),
        Building(positionX: 36, positionY: 84, width: 120, height: 50),
        Building(positionX: 196, positionY: 98, width: 90, height: 70),
        Building(positionX: 30, positionY: 170, width: 150, height: 60),
        Building(positionX: 210, positionY: 200, width: 110, height: 90),
        Building(positionX: 20, positionY: 270, width: 120, height: 70)
    ]
    private let accuracyView = UIImageView(image: UIImage(named: "map-accuracy"))
    private let pinContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        backgroundColor = LocationMapStyle.brandSoft
        clipsToBounds = true
        layer.cornerRadius = 16

        buildings.forEach { _ in
            let view = UIView()
            view.backgroundColor = UIColor.white.withAlphaComponent(0.75)
            view.layer.cornerRadius = 8
            addSubview(view)
        }

        accuracyView.contentMode = .scaleAspectFit
        addSubview(accuracyView)

        pinContainer.backgroundColor = LocationMapStyle.brand
        pinContainer.layer.cornerRadius = 20
        pinContainer.layer.shadowColor = UIColor(
            red: 46 / 255.0,
            green: 135 / 255.0,
            blue: 245 / 255.0,
            alpha: 0.2
        ).cgColor
        pinContainer.layer.shadowOpacity = 1
        pinContainer.layer.shadowRadius = 10
        pinContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        let pin = UIImageView(image: UIImage(named: "map-pin-white"))
        pin.contentMode = .scaleAspectFit
        pin.translatesAutoresizingMaskIntoConstraints = false
        pinContainer.addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: pinContainer.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: pinContainer.centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 20),
            pin.heightAnchor.constraint(equalToConstant: 20)
        ])
        addSubview(pinContainer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = bounds.width / 362
        for (view, building) in zip(subviews.prefix(buildings.count), buildings) {
            view.frame = CGRect(
                x: building.positionX * scale,
                y: building.positionY * scale,
                width: building.width * scale,
                height: building.height * scale
            )
        }
        let pinCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        accuracyView.frame = CGRect(x: pinCenter.x - 48, y: pinCenter.y - 48, width: 96, height: 96)
        pinContainer.frame = CGRect(x: pinCenter.x - 20, y: pinCenter.y - 20, width: 40, height: 40)
    }
}
