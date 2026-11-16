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

    func upload<Response: Decodable>(
        _ path: String,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"clientRequestId\"\r\n\r\n".utf8))
        body.append(Data("\(UUID().uuidString)\r\n--\(boundary)--\r\n".utf8))
        let data = try await perform(
            "POST", path, rawBody: body, contentType: "multipart/form-data; boundary=\(boundary)",
            authenticated: true
        )
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func perform(
        _ method: String,
        _ path: String,
        body: (any Encodable)?,
        authenticated: Bool,
        expiresSessionOnUnauthorized: Bool = true
    ) async throws -> Data {
        let rawBody = try body.map { try encoder.encode($0) }
        return try await perform(
            method, path, rawBody: rawBody, contentType: rawBody == nil ? nil : "application/json",
            authenticated: authenticated, expiresSessionOnUnauthorized: expiresSessionOnUnauthorized
        )
    }

    private func perform(
        _ method: String,
        _ path: String,
        rawBody: Data?,
        contentType: String?,
        authenticated: Bool,
        expiresSessionOnUnauthorized: Bool = true
    ) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.decoding }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let rawBody, let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = rawBody
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
            let errorBody = try? decoder.decode(APIErrorBody.self, from: data)
            let message = errorBody?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            if http.statusCode == 401, authenticated {
                tokenStore.clear()
                if expiresSessionOnUnauthorized {
                    await MainActor.run { AuthSessionRouter.notifySessionExpired() }
                }
                throw APIError.unauthorized(message: message)
            }
            throw APIError.server(
                status: http.statusCode,
                code: errorBody?.code ?? "\(http.statusCode)",
                message: message,
                fieldErrors: errorBody?.errors ?? [:]
            )
        }
        return data
    }
}
