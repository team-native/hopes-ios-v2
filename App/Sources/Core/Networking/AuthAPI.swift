import Foundation

struct TokenResponse: Decodable {
    let accessToken: String
}

struct MessageResponse: Decodable {
    let message: String
}

struct UserResponse: Decodable {
    let username: String
    let email: String
    let nickname: String?
    let profileInfo: String?
    let major: String?
    let cohort: Int?
}

struct SignupPayload: Encodable {
    let email: String
    let username: String
    let password: String
    let passwordConfirm: String
    let verificationCode: String
    let major: String?
    let cohort: Int?
}

enum AuthAPI {
    private static var client: APIClient { .shared }

    static func requestSignupCode(email: String) async throws {
        try await client.send("POST", "/api/signup/email-verifications", body: ["email": email])
    }

    static func confirmSignupCode(email: String, code: String) async throws {
        try await client.send("POST", "/api/signup/email-verifications/confirm", body: ["email": email, "code": code])
    }

    static func signup(_ payload: SignupPayload) async throws {
        let response: TokenResponse = try await client.send("POST", "/api/signup", body: payload)
        AccessTokenStore.shared.save(response.accessToken)
    }

    static func login(email: String, password: String) async throws {
        let response: TokenResponse = try await client.send(
            "POST", "/api/login", body: ["username": email, "password": password]
        )
        AccessTokenStore.shared.save(response.accessToken)
    }

    static func requestPasswordResetCode(email: String) async throws {
        try await client.send("POST", "/api/password/request", body: ["email": email])
    }

    static func resetPassword(email: String, code: String, newPassword: String) async throws {
        try await client.send(
            "POST",
            "/api/password/reset",
            body: ["email": email, "code": code, "newPassword": newPassword, "passwordConfirm": newPassword]
        )
    }

    static func logout() async {
        if AccessTokenStore.shared.hasToken {
            try? await client.send("POST", "/api/logout", authenticated: true, expiresSessionOnUnauthorized: false)
        }
        AccessTokenStore.shared.clear()
    }

    static func fetchMyPage() async throws -> UserResponse {
        try await client.send("GET", "/api/mypage", authenticated: true)
    }

    @MainActor
    static func syncProfile() async {
        guard let user = try? await fetchMyPage() else { return }
        UserProfileStore.shared.update(
            name: user.username,
            department: user.major ?? UserProfileStore.shared.department,
            email: user.email,
            generation: user.cohort.map { "\($0)기" },
            introduction: user.profileInfo
        )
    }
}
