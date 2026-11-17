import XCTest
@testable import Hopes

final class KeepSignedInTests: XCTestCase {
    private let service = "kr.hs.gsm.hopes.tests.keep-signed-in"

    override func tearDown() {
        AccessTokenStore(service: service).clear()
        super.tearDown()
    }

    func testSessionOnlyTokenIsGoneAfterRelaunch() {
        let store = AccessTokenStore(service: service)
        store.save("persisted", persistent: true)
        store.save("session-only", persistent: false)
        XCTAssertEqual(store.token, "session-only")
        XCTAssertTrue(store.isSessionOnly)
        let relaunched = AccessTokenStore(service: service)
        XCTAssertNil(relaunched.token)
    }

    func testKeptSignInSurvivesRelaunch() throws {
        let store = AccessTokenStore(service: service)
        store.save("kept", persistent: true)
        XCTAssertFalse(store.isSessionOnly)
        try XCTSkipIf(store.token == nil, "Keychain is unavailable in the unsigned simulator test host")
        XCTAssertEqual(AccessTokenStore(service: service).token, "kept")
    }

    func testClearRemovesSessionOnlyToken() {
        let store = AccessTokenStore(service: service)
        store.save("session-only", persistent: false)
        store.clear()
        XCTAssertNil(store.token)
    }
}
