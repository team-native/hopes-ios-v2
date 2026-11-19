import Foundation
import XCTest
@testable import Hopes

final class APIClientTransportTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TransportStubURLProtocol.reset()
    }

    func testRejectsHTTPBaseURLBeforeSendingRequest() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let client = APIClient(baseURL: URL(string: "http://example.test")!, session: session)

        do {
            try await client.send("GET", "/api/main")
            XCTFail("HTTP requests must be rejected")
        } catch let error as APIError {
            XCTAssertEqual(error, .insecureTransport)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(TransportStubURLProtocol.requestCount, 0)
    }

    func testRejectsAbsoluteHTTPPathBeforeSendingRequest() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let client = APIClient(baseURL: URL(string: "https://example.test")!, session: session)

        do {
            try await client.send("GET", "http://example.test/api/main")
            XCTFail("Absolute HTTP URLs must be rejected")
        } catch let error as APIError {
            XCTAssertEqual(error, .insecureTransport)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(TransportStubURLProtocol.requestCount, 0)
    }

    func testTLSFailureIsReportedAsInsecureTransport() async {
        TransportStubURLProtocol.errorToThrow = URLError(.secureConnectionFailed)
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let client = APIClient(baseURL: URL(string: "https://example.test")!, session: session)

        do {
            try await client.send("GET", "/api/main")
            XCTFail("TLS failures must be surfaced")
        } catch let error as APIError {
            XCTAssertEqual(error, .insecureTransport)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(TransportStubURLProtocol.requestCount, 1)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TransportStubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private class TransportStubURLProtocol: URLProtocol {
    static var requestCount = 0
    static var errorToThrow: Error?

    static func reset() {
        requestCount = 0
        errorToThrow = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        client?.urlProtocol(self, didFailWithError: Self.errorToThrow ?? URLError(.badServerResponse))
    }

    override func stopLoading() {}
}
