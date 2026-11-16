import Foundation

final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    static let productionBaseURL: URL = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "HopesAPIBaseURL") as? String,
           let url = URL(string: value) {
            return url
        }
        var components = URLComponents()
        components.scheme = "http"
        components.host = "service.gsmsv.site"
        components.port = 22116
        guard let url = components.url else { preconditionFailure("Invalid API base URL") }
        return url
    }()

    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: AccessTokenStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        baseURL: URL = APIClient.productionBaseURL,
        session: URLSession = .shared,
        tokenStore: AccessTokenStore = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
    }

    func send<Response: Decodable>(
        _ method: String,
        _ path: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = false
    ) async throws -> Response {
        let data = try await perform(method, path, body: body, authenticated: authenticated)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    func send(
        _ method: String,
        _ path: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = false,
        expiresSessionOnUnauthorized: Bool = true
    ) async throws {
        _ = try await perform(
            method, path, body: body, authenticated: authenticated,
            expiresSessionOnUnauthorized: expiresSessionOnUnauthorized
        )
    }

    private func perform(
        _ method: String,
        _ path: String,
        body: (any Encodable)?,
        authenticated: Bool,
        expiresSessionOnUnauthorized: Bool = true
    ) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.decoding }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        if authenticated {
            guard let token = tokenStore.token else { throw APIError.unauthorized(message: "로그인이 필요합니다") }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            let body = try? decoder.decode(APIErrorBody.self, from: data)
            let message = body?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            if http.statusCode == 401, authenticated {
                tokenStore.clear()
                if expiresSessionOnUnauthorized {
                    await MainActor.run { AuthSessionRouter.notifySessionExpired() }
                }
                throw APIError.unauthorized(message: message)
            }
            throw APIError.server(
                status: http.statusCode,
                code: body?.code ?? "\(http.statusCode)",
                message: message,
                fieldErrors: body?.errors ?? [:]
            )
        }
        return data
    }
}
