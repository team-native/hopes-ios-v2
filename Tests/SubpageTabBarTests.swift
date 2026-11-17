import XCTest
@testable import Hopes

@MainActor
final class SubpageTabBarTests: XCTestCase {
    func testEveryTabHidesTabBarForPushedScreens() throws {
        let tabs = AppTabBarController()
        tabs.loadViewIfNeeded()
        let navigations = try XCTUnwrap(tabs.viewControllers as? [UINavigationController])
        XCTAssertEqual(navigations.count, 5)
        for navigation in navigations {
            XCTAssertTrue(navigation is AppNavigationController)
            XCTAssertFalse(navigation.viewControllers[0].hidesBottomBarWhenPushed)
        }
        let myPage = navigations[4]
        for screen in [EditProfileViewController(), AIAnswerStyleViewController(), InquiryViewController(),
                       SettingsViewController(), AccountDeletionViewController()] as [UIViewController] {
            myPage.pushViewController(screen, animated: false)
            XCTAssertTrue(screen.hidesBottomBarWhenPushed, "\(type(of: screen)) should hide the tab bar")
            myPage.popToRootViewController(animated: false)
        }
    }
}
