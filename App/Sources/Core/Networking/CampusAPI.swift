import CoreLocation
import Foundation

struct LocationCheckPayload: Encodable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracyMeters: Double
    let measuredAt: String
    let clientRequestId: String
}

struct LocationResultDTO: Decodable {
    let status: String
    let message: String
}

enum CampusAPI {
    static func checkLocation(_ location: CLLocation) async throws -> String {
        let payload = LocationCheckPayload(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracyMeters: max(0, location.horizontalAccuracy),
            measuredAt: ISO8601DateFormatter().string(from: location.timestamp),
            clientRequestId: UUID().uuidString
        )
        let result: LocationResultDTO = try await APIClient.shared.send(
            "POST", "/api/campus/location-check", body: payload, authenticated: true
        )
        return result.status
    }
}
