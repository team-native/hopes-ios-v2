import CoreLocation
import MapKit
import UIKit

@MainActor
final class ChatLocationViewController: UIViewController, @preconcurrency CLLocationManagerDelegate {
    var onLocationSelected: ((String) -> Void)?

    private let locationManager = CLLocationManager()
    private let mapView = MKMapView()
    private let statusLabel = AppStyle.label("위치 권한을 확인하고 있어요", size: 14, color: AppStyle.muted)
    private let sendButton = UIButton(type: .system)
    private let permissionButton = UIButton(type: .system)
    private var currentLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        locationManager.delegate = self

        let title = AppStyle.label("현재 위치", size: 22, weight: .bold)
        let subtitle = AppStyle.label("위치를 질문에 첨부할 수 있어요", size: 14, color: AppStyle.muted)
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
        mapView.heightAnchor.constraint(equalToConstant: 300).isActive = true

        statusLabel.textAlignment = .center
        sendButton.setTitle("현재 위치 첨부", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = AppStyle.blue
        sendButton.layer.cornerRadius = 14
        sendButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        sendButton.isEnabled = false
        sendButton.alpha = 0.5
        sendButton.addAction(UIAction { [weak self] _ in self?.selectLocation() }, for: .touchUpInside)

        permissionButton.setTitle("설정에서 위치 권한 열기", for: .normal)
        permissionButton.isHidden = true
        permissionButton.addAction(UIAction { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, subtitle, mapView, statusLabel, permissionButton, sendButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        renderPermissionState()
    }

    private func renderPermissionState() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            permissionButton.isHidden = true
            statusLabel.text = "위치 권한을 요청할게요"
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            permissionButton.isHidden = true
            statusLabel.text = "현재 위치를 찾고 있어요"
            mapView.showsUserLocation = true
            locationManager.requestLocation()
        case .denied, .restricted:
            permissionButton.isHidden = false
            statusLabel.text = "현재 위치를 보려면 위치 권한을 허용해주세요"
            sendButton.isEnabled = false
            sendButton.alpha = 0.5
        @unknown default:
            statusLabel.text = "위치 권한 상태를 확인할 수 없어요"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        renderPermissionState()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 900, longitudinalMeters: 900)
        mapView.setRegion(region, animated: true)
        statusLabel.text = "현재 위치를 확인했어요"
        sendButton.isEnabled = true
        sendButton.alpha = 1
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusLabel.text = "위치를 확인하지 못했어요. 잠시 후 다시 시도해주세요"
    }

    private func selectLocation() {
        guard let location = currentLocation else { return }
        let value = String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude)
        onLocationSelected?(value)
        dismiss(animated: true)
    }
}
