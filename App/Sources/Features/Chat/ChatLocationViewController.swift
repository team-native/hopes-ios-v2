import CoreLocation
import UIKit

@MainActor
final class ChatLocationViewController: UIViewController, @preconcurrency CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var accuracy: CLLocationAccuracy
    private let accuracyLabel = AppStyle.label("", size: 12, color: LocationMapStyle.secondary)

    init(accuracy: CLLocationAccuracy) {
        self.accuracy = accuracy
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LocationMapStyle.canvas
        locationManager.delegate = self
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }

    private func configureLayout() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "map-back"), for: .normal)
        backButton.tintColor = LocationMapStyle.ink
        backButton.accessibilityLabel = "뒤로"
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        let titleStack = UIStackView(arrangedSubviews: [
            AppStyle.label("학교 지도", size: 18, weight: .medium, color: LocationMapStyle.ink),
            AppStyle.label("현재 위치", size: 12, color: LocationMapStyle.secondary)
        ])
        titleStack.axis = .vertical
        titleStack.spacing = 0
        let header = UIStackView(arrangedSubviews: [backButton, titleStack])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12

        let map = LocationMapIllustrationView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true

        let floorRow = makeFloorRow()
        let locationCard = makeLocationCard()
        let notice = makeNotice()

        let content = UIStackView(arrangedSubviews: [header, map, floorRow, locationCard, notice])
        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            header.heightAnchor.constraint(equalToConstant: 44),
            floorRow.heightAnchor.constraint(equalToConstant: 38),
            locationCard.heightAnchor.constraint(equalToConstant: 76)
        ])
        updateAccuracyLabel()
    }

    private func makeFloorRow() -> UIStackView {
        let floors = UIStackView()
        floors.axis = .horizontal
        floors.alignment = .center
        floors.spacing = 8
        ["1F", "2F", "3F"].forEach { floor in
            let chip = AppStyle.label(floor, size: 14, weight: .medium, color: LocationMapStyle.secondary)
            chip.textAlignment = .center
            chip.backgroundColor = .white
            chip.layer.cornerRadius = 18
            chip.layer.borderWidth = 1
            chip.layer.borderColor = LocationMapStyle.border.cgColor
            chip.clipsToBounds = true
            chip.widthAnchor.constraint(equalToConstant: 45).isActive = true
            chip.heightAnchor.constraint(equalToConstant: 38).isActive = true
            floors.addArrangedSubview(chip)
        }
        let preparation = AppStyle.label("층별 도면 준비 중", size: 12, color: LocationMapStyle.tertiary)
        floors.addArrangedSubview(preparation)
        return floors
    }

    private func makeLocationCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let iconContainer = makeLocationIcon()

        let title = AppStyle.label("본관 부근", size: 15, weight: .medium, color: LocationMapStyle.ink)
        accuracyLabel.numberOfLines = 1
        let labels = UIStackView(arrangedSubviews: [title, accuracyLabel])
        labels.axis = .vertical
        labels.spacing = 2

        let refresh = makeRefreshButton()

        let row = UIStackView(arrangedSubviews: [iconContainer, labels, refresh])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }

    private func makeLocationIcon() -> UIView {
        let container = UIView()
        container.backgroundColor = LocationMapStyle.brandSoft
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 44),
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        let icon = UIImageView(image: UIImage(named: "map-pin-blue"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        return container
    }

    private func makeRefreshButton() -> UIButton {
        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(named: "map-refresh"), for: .normal)
        refresh.tintColor = LocationMapStyle.secondary
        refresh.accessibilityLabel = "위치 다시 측정"
        refresh.addAction(UIAction { [weak self] _ in self?.refreshLocation() }, for: .touchUpInside)
        refresh.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refresh.widthAnchor.constraint(equalToConstant: 36),
            refresh.heightAnchor.constraint(equalToConstant: 44)
        ])
        return refresh
    }

    private func makeNotice() -> UIView {
        let icon = UIImageView(image: UIImage(named: "map-alert"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18)
        ])
        let text = AppStyle.label("실내 도면은 준비 중이에요. 확보되면 층별 지도를 볼 수 있어요.", size: 12, color: LocationMapStyle.secondary)
        text.numberOfLines = 2
        let row = UIStackView(arrangedSubviews: [icon, text])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        row.backgroundColor = LocationMapStyle.brandSoft
        row.layer.cornerRadius = 16
        return row
    }

    private func refreshLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    private func updateAccuracyLabel() {
        accuracyLabel.text = "정확도 약 ±\(Int(accuracy.rounded()))m · 방금 측정"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        accuracy = location.horizontalAccuracy
        updateAccuracyLabel()
    }
}
