import XCTest
@testable import Hopes

@MainActor
final class InquirySubmissionTests: XCTestCase {
    func testInquiryWaitsForAcceptanceAndIgnoresDuplicateSubmit() async {
        let controller = InquiryViewController()
        let navigation = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        navigation.loadViewIfNeeded()
        navigation.view.layoutIfNeeded()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view.window)
        controller.emailField.text = "student@example.com"
        controller.messageView.text = "문의 내용"
        var sendCount = 0
        controller.inquirySender = { _, _ in
            sendCount += 1
            try await Task.sleep(for: .milliseconds(50))
        }

        controller.submit()
        controller.submit()
        XCTAssertTrue(controller.isSubmitting)
        XCTAssertFalse(controller.submitButton?.isEnabled ?? true)

        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(sendCount, 1)
        XCTAssertTrue(navigation.topViewController is InquiryCompletionViewController)
        XCTAssertFalse(controller.isSubmitting)
    }

    func testInquiryUnauthorizedResponseDoesNotShowSuccessOrClearDraft() async {
        let controller = InquiryViewController()
        let navigation = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        navigation.loadViewIfNeeded()
        navigation.view.layoutIfNeeded()
        defer {
            controller.presentedViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view.window)
        controller.emailField.text = "student@example.com"
        controller.messageView.text = "문의 내용"
        controller.inquirySender = { _, _ in
            throw APIError.unauthorized(message: "로그인이 필요합니다")
        }

        controller.submit()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(navigation.topViewController === controller)
        XCTAssertEqual(controller.emailField.text, "student@example.com")
        XCTAssertEqual(controller.messageView.text, "문의 내용")
        XCTAssertFalse(controller.isSubmitting)
        XCTAssertTrue(controller.submitButton?.isEnabled ?? false)
        XCTAssertEqual((controller.presentedViewController as? UIAlertController)?.message, "로그인이 필요합니다")
    }
}
