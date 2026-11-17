import XCTest
@testable import Hopes

final class LoginFailureTests: XCTestCase {
    func testUnauthorizedIsInvalidCredentials() {
        XCTAssertEqual(
            LoginFailure.classify(APIError.unauthorized(message: "unauthorized")),
            .invalidCredentials
        )
    }

    func testNetworkFailureIsOffline() {
        XCTAssertEqual(LoginFailure.classify(APIError.network), .offline)
    }

    func testRateLimitIsRetryableServerFailure() {
        XCTAssertEqual(LoginFailure.classify(serverError(status: 429)), .rateLimited)
    }

    func testOtherServerAndDecodingFailuresAreGenericServerErrors() {
        XCTAssertEqual(LoginFailure.classify(serverError(status: 503)), .serverError)
        XCTAssertEqual(LoginFailure.classify(APIError.decoding), .serverError)
        XCTAssertEqual(LoginFailure.classify(URLError(.badServerResponse)), .serverError)
    }

    private func serverError(status: Int) -> APIError {
        .server(status: status, code: "SERVER_ERROR", message: "private server detail", fieldErrors: [:])
    }
}
