import XCTest
@testable import Hopes

@MainActor
final class LoginFieldStretchTests: XCTestCase {
    func testPasswordFieldKeepsHeightThroughRetryStates() {
        let login = LoginViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = login
        window.makeKeyAndVisible()
        login.view.layoutIfNeeded()
        func heights() -> (CGFloat, CGFloat) {
            login.view.layoutIfNeeded()
            return (login.emailField.frame.height, login.passwordField.frame.height)
        }
        XCTAssertEqual(heights().1, 54, accuracy: 0.5)
        login.textFieldDidBeginEditing(login.passwordField)
        XCTAssertEqual(heights().1, 55, accuracy: 0.5)
        let sequence: [LoginViewController.Feedback] = [.loading, .serverError, .loading, .offline, .loading,
            .invalidCredentials, .loading, .serverError]
        for state in sequence {
            login.feedback = state
            login.applyFeedback()
            let (email, password) = heights()
            XCTAssertLessThanOrEqual(email, 55.5, "\(state)")
            XCTAssertLessThanOrEqual(password, 55.5, "\(state)")
            XCTAssertGreaterThanOrEqual(password, 53.5, "\(state)")
        }
    }
}

@MainActor
final class LoginKeyboardFieldTests: XCTestCase {
    func testKeyboardLayoutDoesNotStretchFields() {
        let login = LoginViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = login
        window.makeKeyAndVisible()
        login.view.layoutIfNeeded()
        for mode in [LoginViewController.LayoutMode.keyboard, .full, .sheet, .keyboard] {
            login.setLayoutMode(mode)
            login.view.layoutIfNeeded()
            XCTAssertLessThanOrEqual(login.passwordField.frame.height, 55.5, "\(mode)")
            XCTAssertLessThanOrEqual(login.emailField.frame.height, 55.5, "\(mode)")
        }
    }
}
