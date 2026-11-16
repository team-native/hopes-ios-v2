import XCTest
@testable import Hopes

final class APIClientTransportTests: XCTestCase {
    func testHTTPBaseURLIsRejectedBeforeSendingRequest() async {
        let client = APIClient(baseURL: URL(string: "http://service.gsmsv.site:22116")!)

        do {
            let _: EmptyResponse = try await client.send("GET", "/api/main")
            XCTFail("An HTTP request must be rejected before it is sent")
        } catch let error as APIError {
            XCTAssertEqual(error, .insecureTransport)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHTTPAbsolutePathIsRejectedAgainstHTTPSBaseURL() async {
        let client = APIClient(baseURL: URL(string: "https://service.gsmsv.site")!)

        do {
            let _: EmptyResponse = try await client.send("GET", "http://service.gsmsv.site/api/main")
            XCTFail("An HTTP URL override must be rejected before it is sent")
        } catch let error as APIError {
            XCTAssertEqual(error, .insecureTransport)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct EmptyResponse: Decodable {}
