import XCTest
@testable import Hopes

@MainActor
final class LoginSignupTapTests: XCTestCase {
    private func makeLogin() -> (LoginViewController, UINavigationController) {
        let login = LoginViewController()
        let nav = UINavigationController(rootViewController: login)
        nav.setNavigationBarHidden(true, animated: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        login.view.layoutIfNeeded()
        return (login, nav)
    }

    func testSignupRowAcceptsTouchesAcrossPromptAndAboveRow() {
        let (login, _) = makeLogin()
        let row = login.signupRow
        let prompt = row.convert(CGPoint(x: row.bounds.midX - 40, y: row.bounds.midY), to: login.view)
        let above = row.convert(CGPoint(x: row.bounds.midX, y: -10), to: login.view)
        for point in [prompt, above] {
            var hit = login.view.hitTest(point, with: nil)
            while let view = hit, view !== row { hit = view.superview }
            XCTAssertTrue(hit === row, "\(point) should land in signup row")
        }
        XCTAssertGreaterThanOrEqual(row.bounds.inset(by: row.touchInsets).height, 44)
    }

    func testSignupButtonOpensSignupWithoutSlidingLoginAway() {
        let (login, nav) = makeLogin()
        let button = login.signupRow.arrangedSubviews.compactMap { $0 as? UIButton }.first
        XCTAssertEqual(button?.accessibilityIdentifier, "login-signup")
        button?.sendActions(for: .touchUpInside)
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        XCTAssertEqual(nav.viewControllers.count, 1)
        let presented = login.presentedViewController as? UINavigationController
        XCTAssertTrue(presented?.viewControllers.first is SignupViewController)
        XCTAssertEqual(presented?.modalTransitionStyle, .crossDissolve)
    }
}
