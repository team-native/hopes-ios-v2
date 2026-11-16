import Foundation

struct CategoryDTO: Decodable {
    let id: Int64
    let name: String
    let isActive: Bool
}

struct RecommendationDTO: Decodable {
    let id: Int64
    let content: String
}

struct RecommendationResultDTO: Decodable {
    let items: [RecommendationDTO]
    let fallbackUsed: Bool
    let nextRefreshToken: String
}

struct ChatPreferencesPayload: Encodable {
    let departmentId: Int64?
    let specialtyId: Int64?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(departmentId, forKey: .departmentId)
        try container.encode(specialtyId, forKey: .specialtyId)
    }

    enum CodingKeys: String, CodingKey { case departmentId, specialtyId }
}

enum CatalogAPI {
    private static var client: APIClient { .shared }
    private static var departmentIDs: [String: Int64] = ["소프트웨어개발과": 1, "스마트IoT과": 2, "인공지능과": 3]
    private static var specialtyIDs: [String: Int64] = [
        "iOS": 101, "Android": 102, "Frontend": 103, "Backend": 104, "AI": 105,
        "IoT": 106, "DevOps": 107, "Design": 108, "기타": 109
    ]

    static func departmentID(for name: String?) -> Int64? { name.flatMap { departmentIDs[$0] } }
    static func specialtyID(for name: String?) -> Int64? { name.flatMap { specialtyIDs[$0] } }

    static func refreshCatalogs() async {
        guard AccessTokenStore.shared.hasToken else { return }
        if let departments: [CategoryDTO] = try? await client.send("GET", "/api/departments", authenticated: true) {
            departmentIDs = Dictionary(departments.filter(\.isActive).map { ($0.name, $0.id) }) { first, _ in first }
        }
        if let specialties: [CategoryDTO] = try? await client.send("GET", "/api/specialties", authenticated: true) {
            specialtyIDs = Dictionary(specialties.filter(\.isActive).map { ($0.name, $0.id) }) { first, _ in first }
        }
    }

    static func savePreferences(department: String?, specialty: String?) async {
        guard AccessTokenStore.shared.hasToken else { return }
        let payload = ChatPreferencesPayload(
            departmentId: departmentID(for: department),
            specialtyId: specialtyID(for: specialty)
        )
        try? await client.send("PATCH", "/api/chat-preferences", body: payload, authenticated: true)
    }

    static func recommendations(
        department: String?,
        specialty: String?,
        refreshToken: String?,
        excludeIDs: [Int64]
    ) async throws -> RecommendationResultDTO {
        var items = [URLQueryItem(name: "limit", value: "4")]
        if let id = departmentID(for: department) { items.append(URLQueryItem(name: "departmentId", value: "\(id)")) }
        if let id = specialtyID(for: specialty) { items.append(URLQueryItem(name: "specialtyId", value: "\(id)")) }
        if let refreshToken { items.append(URLQueryItem(name: "refreshToken", value: refreshToken)) }
        if !excludeIDs.isEmpty {
            items.append(URLQueryItem(name: "excludeIds", value: excludeIDs.map(String.init).joined(separator: ",")))
        }
        var components = URLComponents()
        components.path = "/api/question-recommendations"
        components.queryItems = items
        return try await client.send("GET", components.string ?? components.path, authenticated: true)
    }
}
