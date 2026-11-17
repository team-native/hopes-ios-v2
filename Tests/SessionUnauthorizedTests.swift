import XCTest
@testable import Hopes

final class SessionUnauthorizedTests: XCTestCase {
    func testUnauthorizedResponseRespectsSessionExpiryPolicy() async throws {
        let tokenStore = AccessTokenStore.shared
        let previousToken = tokenStore.token
        let testToken = "session-policy-test-token"
        tokenStore.save(testToken)
        defer {
            if let previousToken {
                tokenStore.save(previousToken)
            } else {
                tokenStore.clear()
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UnauthorizedStubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        UnauthorizedStubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"code":"UNAUTHORIZED","message":"비밀번호가 일치하지 않습니다"}"#.utf8))
        }
        defer { UnauthorizedStubURLProtocol.requestHandler = nil }

        let client = APIClient(baseURL: URL(string: "https://example.test")!, session: session)

        do {
            try await client.send(
                "DELETE", "/api/account", body: ["password": "incorrect"],
                authenticated: true, expiresSessionOnUnauthorized: false
            )
            XCTFail("A 401 response must be surfaced as an authorization error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized(message: "비밀번호가 일치하지 않습니다"))
        }
        XCTAssertEqual(tokenStore.token, testToken)

        do {
            try await client.send("GET", "/api/main", authenticated: true)
            XCTFail("A session-expiring 401 response must be surfaced as an authorization error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized(message: "비밀번호가 일치하지 않습니다"))
        }
        XCTAssertNil(tokenStore.token)
    }
}

private class UnauthorizedStubURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
