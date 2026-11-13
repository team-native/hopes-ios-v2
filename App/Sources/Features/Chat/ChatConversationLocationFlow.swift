import CoreLocation
import MapKit
import UIKit

@MainActor
extension ChatConversationViewController {
    func beginLocationMeasurement(isRetry: Bool = false) {
        if !isRetry { addUserMessage("지금 내 위치 알려줘") }
        hasPendingLocationRequest = true

        switch locationManager.authorizationStatus {
        case .notDetermined:
            showLocationPermissionCard()
        case .authorizedAlways, .authorizedWhenInUse:
            showLocationMeasurementCard()
            locationManager.requestLocation()
        case .denied, .restricted:
            showLocationFailure()
        @unknown default:
            showLocationFailure()
        }
    }

    func showLocationPermissionCard() {
        let card = ChatLocationPermissionCardView(
            onLater: { [weak self] in self?.cancelLocationRequest() },
            onAllow: { [weak self] in self?.requestLocationPermission() }
        )
        replaceLocationCard(with: card)
        scrollToLatestMessage()
    }

    func requestLocationPermission() {
        showLocationMeasurementCard()
        locationManager.requestWhenInUseAuthorization()
    }

    func showLocationMeasurementCard() {
        replaceLocationCard(with: makeLocationMeasurementCard())
        scrollToLatestMessage()
    }

    func cancelLocationRequest() {
        hasPendingLocationRequest = false
        guard let locationCard else { return }
        messagesStack.removeArrangedSubview(locationCard)
        locationCard.removeFromSuperview()
        self.locationCard = nil
    }

    func showLocationFailure() {
        guard hasPendingLocationRequest else { return }
        let failure = ChatLocationFailureCardView(
            onSettingsRequested: { [weak self] in self?.openLocationSettings() },
            onRetryRequested: { [weak self] in self?.beginLocationMeasurement(isRetry: true) }
        )
        replaceLocationCard(with: failure)
        scrollToLatestMessage()
    }

    func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func makeLocationMeasurementCard() -> UIView {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let iconContainer = UIView()
        iconContainer.backgroundColor = AppStyle.paleBlue
        iconContainer.layer.cornerRadius = 12
        iconContainer.widthAnchor.constraint(equalToConstant: 44).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let pinPath = Bundle.main.path(forResource: "chat-location-pin", ofType: "png")
        let pin = UIImageView(image: pinPath.flatMap(UIImage.init(contentsOfFile:)))
        pin.contentMode = .scaleAspectFit
        pin.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 24),
            pin.heightAnchor.constraint(equalToConstant: 24)
        ])
        let title = AppStyle.label("현재 위치를 확인하고 있어요…", size: 15, weight: .medium)
        let subtitle = AppStyle.label("잠시만 기다려 주세요. 보통 몇 초면 끝나요.", size: 12, color: AppStyle.muted)
        subtitle.numberOfLines = 1
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 2
        let row = UIStackView(arrangedSubviews: [iconContainer, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0.42
        progress.progressTintColor = AppStyle.blue
        progress.trackTintColor = UIColor(red: 0.90, green: 0.94, blue: 0.99, alpha: 1)
        progress.layer.cornerRadius = 3
        progress.clipsToBounds = true
        progress.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let content = UIStackView(arrangedSubviews: [row, progress])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    func replaceLocationCard(with card: UIView) {
        if let locationCard, let index = messagesStack.arrangedSubviews.firstIndex(of: locationCard) {
            messagesStack.removeArrangedSubview(locationCard)
            locationCard.removeFromSuperview()
            messagesStack.insertArrangedSubview(card, at: index)
        } else {
            messagesStack.addArrangedSubview(card)
        }
        locationCard = card
    }

    func openSchoolMap() {
        guard navigationController != nil else { return }
        let map = ChatLocationViewController(accuracy: measuredLocationAccuracy)
        navigationController?.pushViewController(map, animated: true)
    }

    func makeLowAccuracyCard(accuracy: CLLocationAccuracy) -> UIView {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("학교 근처로 보이지만 위치 정확도가 낮아요.", size: 15)
        let warning = UIStackView()
        warning.axis = .horizontal
        warning.alignment = .center
        warning.spacing = 8
        warning.isLayoutMarginsRelativeArrangement = true
        warning.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        warning.backgroundColor = UIColor(red: 1, green: 0.94, blue: 0.95, alpha: 1)
        warning.layer.cornerRadius = 16
        let alertPath = Bundle.main.path(forResource: "location-low-accuracy-alert", ofType: "png")
        let alertIcon = UIImageView(image: alertPath.flatMap(UIImage.init(contentsOfFile:)))
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let accuracyLabel = AppStyle.label(
            "정확도 약 ±\(Int(accuracy.rounded()))m · 실내에서는 오차가 커질 수 있어요.",
            size: 12,
            color: AppStyle.muted
        )
        accuracyLabel.numberOfLines = 1
        warning.addArrangedSubview(alertIcon)
        warning.addArrangedSubview(accuracyLabel)

        let retryButton = UIButton(type: .system)
        var retryConfiguration = UIButton.Configuration.plain()
        retryConfiguration.title = "다시 측정"
        retryConfiguration.baseForegroundColor = AppStyle.blue
        retryConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        retryButton.configuration = retryConfiguration
        retryButton.backgroundColor = .white
        retryButton.layer.cornerRadius = 10
        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        retryButton.addAction(UIAction { [weak self] _ in
            self?.beginLocationMeasurement(isRetry: true)
        }, for: .touchUpInside)

        let mapButton = UIButton(type: .system)
        var mapConfiguration = UIButton.Configuration.filled()
        mapConfiguration.title = "지도 보기"
        mapConfiguration.baseBackgroundColor = AppStyle.paleBlue
        mapConfiguration.baseForegroundColor = AppStyle.blue
        mapConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        mapButton.configuration = mapConfiguration
        mapButton.layer.cornerRadius = 10
        mapButton.clipsToBounds = true
        mapButton.addAction(UIAction { [weak self] _ in self?.openSchoolMap() }, for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [retryButton, mapButton])
        buttons.axis = .horizontal
        buttons.spacing = 8
        buttons.distribution = .fillEqually

        let content = UIStackView(arrangedSubviews: [title, warning, buttons])
        content.axis = .vertical
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 14, bottom: 14, trailing: 14)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard hasPendingLocationRequest else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            showLocationMeasurementCard()
            manager.requestLocation()
        case .denied, .restricted:
            showLocationFailure()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        measuredLocation = location.coordinate
        measuredLocationAccuracy = location.horizontalAccuracy
        let schoolLocation = CLLocation(latitude: 35.142829306650874, longitude: 126.80021878005266)
        let distanceInMeters = schoolLocation.distance(from: location)
        if distanceInMeters > 250 {
            hasPendingLocationRequest = false
            let distanceText = distanceInMeters >= 1_000
                ? String(format: "%.1fkm", distanceInMeters / 1_000)
                : "\(Int(distanceInMeters.rounded()))m"
            let outsideCard = ChatLocationOutsideSchoolCardView(distance: distanceText) { [weak self] in
                self?.openMeasuredLocationInMaps()
            }
            replaceLocationCard(with: outsideCard)
            scrollToLatestMessage()
            return
        }
        if location.horizontalAccuracy > 100 {
            hasPendingLocationRequest = false
            let card = makeLowAccuracyCard(accuracy: location.horizontalAccuracy)
            replaceLocationCard(with: card)
            scrollToLatestMessage()
            return
        }
        hasPendingLocationRequest = false
        let result = ChatLocationResultCardView(accuracy: location.horizontalAccuracy) { [weak self] in
            self?.openSchoolMap()
        }
        replaceLocationCard(with: result)
        scrollToLatestMessage()
    }

    func openMeasuredLocationInMaps() {
        guard let measuredLocation else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: measuredLocation))
        item.name = "현재 위치"
        item.openInMaps(launchOptions: [MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue])
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showLocationFailure()
    }

    func scrollToLatestMessage() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let bottom = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height))
            self.scrollView.setContentOffset(bottom, animated: true)
        }
    }

}
