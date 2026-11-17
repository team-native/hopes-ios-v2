import Foundation

struct SettingMainDTO: Decodable {
    let customPrompt: String
}

enum AccountAPI {
    private static var client: APIClient { .shared }

    static func updateProfile(username: String, profileInfo: String) async throws {
        let _: UserResponse = try await client.send(
            "PATCH", "/api/mypage", body: ["username": username, "profileInfo": profileInfo], authenticated: true
        )
    }

    static func settingMain() async throws -> SettingMainDTO {
        try await client.send("GET", "/api/setting/main", authenticated: true)
    }

    static func updateCustomPrompt(_ prompt: String) async throws {
        try await client.send("PATCH", "/api/setting", body: ["customPrompt": prompt], authenticated: true)
    }

    static func deleteAccount(password: String) async throws {
        try await client.send(
            "DELETE", "/api/account", body: ["password": password], authenticated: true,
            expiresSessionOnUnauthorized: false
        )
    }

    static func sendInquiry(email: String, message: String) async throws {
        let content = "답변 받을 이메일: \(email)\n\n\(message)"
        try await client.send("POST", "/api/setting/inquiry", body: ["content": content], authenticated: true)
    }
}
