import XCTest
@testable import Hopes

@MainActor
final class LoginKeyboardIsolationTests: XCTestCase {
    func testKeyboardFromAnotherScreenDoesNotMoveLoginSheet() {
        let login = LoginViewController()
        login.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        login.loadViewIfNeeded()
        login.view.layoutIfNeeded()
        XCTAssertEqual(login.mode, .sheet)
        login.handleKeyboardFrame(CGRect(x: 0, y: 538, width: 402, height: 336))
        XCTAssertEqual(login.mode, .sheet)
        login.handleKeyboardFrame(CGRect(x: 0, y: 874, width: 402, height: 336))
        XCTAssertEqual(login.mode, .sheet)
    }
}
