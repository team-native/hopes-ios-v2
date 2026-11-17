import XCTest
@testable import Hopes

@MainActor
final class TabBarOverlapTests: XCTestCase {
    func testChatPushPopKeepsSingleCustomBarAndHiddenNativeBar() throws {
        let tabs = AppTabBarController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        tabs.selectedIndex = 1
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        let nav = try XCTUnwrap(tabs.selectedViewController as? UINavigationController)
        for _ in 0..<3 {
            nav.pushViewController(ChatConversationViewController(question: nil), animated: false)
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            XCTAssertEqual(tabs.tabBar.alpha, 0)
            XCTAssertTrue(self.customBar(in: window)?.isHidden ?? false)
            nav.popViewController(animated: false)
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            (nav.topViewController as? ChatHomeViewController)?.refreshQuestions()
            tabs.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            XCTAssertEqual(tabs.tabBar.alpha, 0, "native tab bar must stay invisible after pop")
            XCTAssertTrue(tabs.tabBar.items?.allSatisfy { $0.title == nil && $0.image == nil } ?? false)
            XCTAssertEqual(self.customBar(in: window)?.isHidden, false)
        }
        let bars = window.allSubviews.filter { $0.accessibilityIdentifier == "app-custom-tab-bar" }
        XCTAssertEqual(bars.count, 1)
        XCTAssertEqual(bars.first?.isHidden, false)
    }

    private func customBar(in window: UIWindow) -> UIView? {
        window.allSubviews.first { $0.accessibilityIdentifier == "app-custom-tab-bar" }
    }
}

private extension UIView {
    var allSubviews: [UIView] { subviews + subviews.flatMap(\.allSubviews) }
}
