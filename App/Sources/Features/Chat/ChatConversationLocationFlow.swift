import CoreLocation
import MapKit
import UIKit

@MainActor
extension ChatConversationViewController {
    func isLocationMeasurementRequest(_ question: String) -> Bool {
        let normalized = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return ["현재 위치 알려", "현재 위치 확인", "내 위치 알려", "내 위치 확인", "지금 어디"]
            .contains(where: normalized.contains)
    }

    func beginLocationMeasurement(question: String = "지금 내 위치 알려줘", isRetry: Bool = false) {
        setLocationConversationHeader(active: true)
        if !isRetry { addUserMessage(question, isLocationRequest: true) }
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
        removeLocationCard()
        locationManager.requestWhenInUseAuthorization()
    }

    func showLocationMeasurementCard() {
        replaceLocationCard(with: makeLocationMeasurementCard())
        scrollToLatestMessage()
    }

    func cancelLocationRequest() {
        hasPendingLocationRequest = false
        setLocationConversationHeader(active: false)
        removeLocationCard()
    }

    private func removeLocationCard() {
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
        let card = ChatConversationBubbleView(
            fillColor: .white,
            topLeftRadius: 6,
            topRightRadius: 24,
            bottomRightRadius: 24,
            bottomLeftRadius: 24,
            borderColor: ChatDetailPalette.border
        )
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let row = makeLocationMeasurementRow()
        let progress = makeLocationProgressView()
        let content = UIStackView(arrangedSubviews: [row, progress])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
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

    private func makeLocationMeasurementRow() -> UIStackView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = ChatDetailPalette.brandSoft
        iconContainer.layer.cornerRadius = 12
        iconContainer.widthAnchor.constraint(equalToConstant: 44).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let pin = UIImageView(image: UIImage(named: "ChatConversationLocationPin"))
        pin.contentMode = .scaleAspectFit
        pin.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 22),
            pin.heightAnchor.constraint(equalToConstant: 22)
        ])
        let title = AppStyle.label(
            "현재 위치를 확인하고 있어요…",
            size: 15,
            weight: .medium,
            color: ChatDetailPalette.ink
        )
        applyLineHeight(title, lineHeight: 24, height: 24, kern: -0.1)
        let subtitle = AppStyle.label(
            "잠시만 기다려 주세요. 보통 몇 초면 끝나요.",
            size: 12,
            color: ChatDetailPalette.muted
        )
        applyLineHeight(subtitle, lineHeight: 16, height: 16)
        subtitle.numberOfLines = 1
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 2
        let row = UIStackView(arrangedSubviews: [iconContainer, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        return row
    }

    private func makeLocationProgressView() -> UIView {
        let track = UIView()
        track.backgroundColor = ChatDetailPalette.brandSoft
        track.layer.cornerRadius = 3
        track.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let fill = UIView()
        fill.backgroundColor = ChatDetailPalette.brand
        fill.layer.cornerRadius = 3
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)
        NSLayoutConstraint.activate([
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalToConstant: 140)
        ])
        return track
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
        let card = ChatConversationBubbleView(
            fillColor: .white,
            topLeftRadius: 6,
            topRightRadius: 24,
            bottomRightRadius: 24,
            bottomLeftRadius: 24,
            borderColor: LocationMapStyle.subtleBorder
        )
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        let content = makeLowAccuracyContent(accuracy: accuracy)
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

    private func makeLowAccuracyContent(accuracy: CLLocationAccuracy) -> UIStackView {
        let title = AppStyle.label(
            "학교 근처로 보이지만 위치 정확도가 낮아요.",
            size: 15,
            color: LocationMapStyle.ink
        )
        let warning = makeAccuracyWarning(accuracy: accuracy)
        let buttons = makeAccuracyActions()
        let content = UIStackView(arrangedSubviews: [title, warning, buttons])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return content
    }

    private func makeAccuracyWarning(accuracy: CLLocationAccuracy) -> UIStackView {
        let warning = UIStackView()
        warning.axis = .horizontal
        warning.alignment = .center
        warning.spacing = 8
        warning.isLayoutMarginsRelativeArrangement = true
        warning.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        warning.backgroundColor = UIColor(red: 1, green: 241 / 255.0, blue: 242 / 255.0, alpha: 1)
        warning.layer.cornerRadius = 16
        let alertIcon = UIImageView(image: UIImage(named: "location-low-accuracy-alert"))
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let accuracyLabel = AppStyle.label(
            "정확도 약 ±\(Int(accuracy.rounded()))m · 실내에서는 오차가 커질 수 있어요.",
            size: 12,
            color: LocationMapStyle.secondary
        )
        accuracyLabel.numberOfLines = 0
        accuracyLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        warning.addArrangedSubview(alertIcon)
        warning.addArrangedSubview(accuracyLabel)
        return warning
    }

    private func makeAccuracyActions() -> UIStackView {
        let retryButton = UIButton(type: .system)
        var retryConfiguration = UIButton.Configuration.filled()
        retryConfiguration.title = "다시 측정"
        retryConfiguration.baseBackgroundColor = .white
        retryConfiguration.baseForegroundColor = LocationMapStyle.brand
        retryConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        retryConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        retryButton.configuration = retryConfiguration
        retryButton.backgroundColor = .white
        retryButton.layer.cornerRadius = 10
        retryButton.clipsToBounds = true
        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        retryButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        retryButton.addAction(UIAction { [weak self] _ in
            self?.beginLocationMeasurement(isRetry: true)
        }, for: .touchUpInside)

        let mapButton = UIButton(type: .system)
        var mapConfiguration = UIButton.Configuration.filled()
        mapConfiguration.title = "지도 보기"
        mapConfiguration.baseBackgroundColor = LocationMapStyle.brandSoft
        mapConfiguration.baseForegroundColor = LocationMapStyle.brand
        mapConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        mapConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        mapButton.configuration = mapConfiguration
        mapButton.layer.cornerRadius = 10
        mapButton.clipsToBounds = true
        mapButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        mapButton.addAction(UIAction { [weak self] _ in self?.openSchoolMap() }, for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [retryButton, mapButton])
        buttons.axis = .horizontal
        buttons.spacing = 8
        buttons.distribution = .fillEqually
        return buttons
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
        guard AccessTokenStore.shared.hasToken else {
            showLocationOutcome(for: location, serverStatus: nil)
            return
        }
        Task { [weak self] in
            let status = try? await CampusAPI.checkLocation(location)
            self?.showLocationOutcome(for: location, serverStatus: status)
        }
    }

    func showLocationOutcome(for location: CLLocation, serverStatus: String?) {
        let schoolLocation = CLLocation(latitude: 35.142829306650874, longitude: 126.80021878005266)
        let distanceInMeters = schoolLocation.distance(from: location)
        let isOutside = serverStatus.map { $0 == "OUTSIDE" } ?? (distanceInMeters > 250)
        let isLowAccuracy = serverStatus.map { $0 == "LOW_ACCURACY" } ?? (location.horizontalAccuracy > 100)
        if isOutside {
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
        if isLowAccuracy {
            hasPendingLocationRequest = false
            let card = makeLowAccuracyCard(accuracy: location.horizontalAccuracy)
            replaceLocationCard(with: card)
            scrollToLatestMessage()
            return
        }
        hasPendingLocationRequest = false
        let result = ChatLocationResultMessageView(accuracy: location.horizontalAccuracy) { [weak self] in
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
