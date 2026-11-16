import Foundation

private final class APIUploadProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let onProgress: @Sendable (Int64, Int64) -> Void

    init(onProgress: @escaping @Sendable (Int64, Int64) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        onProgress(totalBytesSent, totalBytesExpectedToSend)
    }
}

final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    static let productionBaseURL: URL = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "HopesAPIBaseURL") as? String,
           let url = URL(string: value) {
            return url
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "service.gsmsv.site"
        guard let url = components.url else { preconditionFailure("Invalid API base URL") }
        return url
    }()

    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: any AccessTokenStoring
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        baseURL: URL = APIClient.productionBaseURL,
        session: URLSession = .shared,
        tokenStore: any AccessTokenStoring = AccessTokenStore.shared
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
        mimeType: String,
        clientRequestId: String,
        onProgress: @escaping @Sendable (Int64, Int64) -> Void = { _, _ in }
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"clientRequestId\"\r\n\r\n".utf8))
        body.append(Data("\(clientRequestId)\r\n--\(boundary)--\r\n".utf8))
        let data = try await perform(
            "POST", path, rawBody: body, contentType: "multipart/form-data; boundary=\(boundary)",
            authenticated: true, uploadProgress: onProgress
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
        expiresSessionOnUnauthorized: Bool = true,
        uploadProgress: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL),
              url.scheme?.lowercased() == "https" else {
            throw APIError.insecureTransport
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let rawBody, let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            if uploadProgress == nil { request.httpBody = rawBody }
        }
        if authenticated {
            guard let token = tokenStore.token else { throw APIError.unauthorized(message: "로그인이 필요합니다") }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await send(request, body: rawBody, uploadProgress: uploadProgress)
        } catch {
            if error is CancellationError { throw error }
            throw APIError.network
        }
        return try await validate(data: data, response: response, authenticated: authenticated,
                                  expiresSessionOnUnauthorized: expiresSessionOnUnauthorized)
    }

    private func validate(
        data: Data,
        response: URLResponse,
        authenticated: Bool,
        expiresSessionOnUnauthorized: Bool
    ) async throws -> Data {
        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            let errorBody = try? decoder.decode(APIErrorBody.self, from: data)
            let message = errorBody?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            if http.statusCode == 401, authenticated {
                if expiresSessionOnUnauthorized {
                    tokenStore.clear()
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

    private func send(
        _ request: URLRequest,
        body: Data?,
        uploadProgress: (@Sendable (Int64, Int64) -> Void)?
    ) async throws -> (Data, URLResponse) {
        guard let uploadProgress, let body else {
            return try await session.data(for: request)
        }
        let delegate = APIUploadProgressDelegate(onProgress: uploadProgress)
        return try await session.upload(for: request, from: body, delegate: delegate)
    }
}
