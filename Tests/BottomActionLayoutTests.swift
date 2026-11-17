import XCTest
@testable import Hopes

@MainActor
final class BottomActionLayoutTests: XCTestCase {
    func testActionsFollowSafeAreaInsteadOfScreenBottom() throws {
        let screens: [(UIViewController, String)] = [
            (EditProfileViewController(), "profile-edit-save"),
            (AIAnswerStyleViewController(), "ai-answer-style-save-bottom"),
            (InquiryViewController(), "inquiry-submit")
        ]
        for (screen, identifier) in screens {
            screen.loadViewIfNeeded()
            screen.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            screen.additionalSafeAreaInsets.bottom = 80
            screen.view.layoutIfNeeded()
            let button = try XCTUnwrap(screen.view.subviews.first { $0.accessibilityIdentifier == identifier })
            XCTAssertLessThanOrEqual(button.frame.maxY, screen.view.safeAreaLayoutGuide.layoutFrame.maxY - 11)
        }
    }
}
