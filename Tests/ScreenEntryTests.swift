import XCTest
@testable import Hopes

@MainActor
final class ScreenEntryTests: XCTestCase {
    func testHistoryResponseRebuildsBetweenEmptyAndPopulated() {
        let controller = HistoryViewController()
        controller.conversations = []
        controller.loadViewIfNeeded()
        for _ in 0..<3 {
            controller.conversations = [HistoryViewController.Conversation(
                title: "회귀 테스트", time: "오늘", department: "테스트", olderThanWeek: false
            )]
            controller.buildContent()
            controller.view.layoutIfNeeded()
            XCTAssertFalse(controller.resultsStack.arrangedSubviews.isEmpty)
            controller.conversations = []
            controller.buildContent()
            controller.view.layoutIfNeeded()
            XCTAssertFalse(controller.contentStack.arrangedSubviews.isEmpty)
        }
    }

    func testNavigationPushPopForAffectedScreens() async {
        let root = CommunityViewController()
        let navigation = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        navigation.loadViewIfNeeded()
        navigation.view.layoutIfNeeded()
        let rootDisplayed = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in root.view.window != nil }, object: nil
        )
        await fulfillment(of: [rootDisplayed], timeout: 3)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let history = HistoryViewController()
        history.conversations = []
        let screens: [UIViewController] = [
            history, CommunitySearchViewController(), MyActivityViewController(),
            NotificationsViewController(), SettingsViewController(), ChatConversationViewController(question: nil)
        ]
        for screen in screens {
            navigation.pushViewController(screen, animated: false)
            navigation.view.layoutIfNeeded()
            screen.view.layoutIfNeeded()
            XCTAssertTrue(navigation.topViewController === screen)
            let displayed = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in screen.view.window != nil }, object: nil
            )
            displayed.expectationDescription = "Display \(type(of: screen))"
            await fulfillment(of: [displayed], timeout: 3)
            navigation.popViewController(animated: false)
            XCTAssertTrue(navigation.topViewController === root)
            (screen as? ChatConversationViewController)?.networkMonitor.cancel()
        }
    }

    func testRepeatedTabTransitions() {
        let tabs = AppTabBarController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        tabs.loadViewIfNeeded()
        XCTAssertEqual(tabs.viewControllers?.count, 5)
        for _ in 0..<3 {
            for index in [0, 1, 2, 3, 4, 3, 2, 1, 0] {
                tabs.selectedIndex = index
                tabs.selectedViewController?.loadViewIfNeeded()
                tabs.view.layoutIfNeeded()
                XCTAssertEqual(tabs.selectedIndex, index)
                XCTAssertNotNil(tabs.selectedViewController?.view.window)
            }
        }
    }

    func testRepeatedTabTransitionsWithEmptyHistory() throws {
        let tabs = AppTabBarController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        tabs.loadViewIfNeeded()
        let historyNavigation = try XCTUnwrap(tabs.viewControllers?[3] as? UINavigationController)
        let history = try XCTUnwrap(historyNavigation.viewControllers.first as? HistoryViewController)
        history.conversations = []

        for _ in 0..<3 {
            for index in [3, 0, 1, 2, 4, 3] {
                tabs.selectedIndex = index
                tabs.selectedViewController?.loadViewIfNeeded()
                tabs.view.layoutIfNeeded()
                XCTAssertEqual(tabs.selectedIndex, index)
                XCTAssertNotNil(tabs.selectedViewController?.view.window)
            }
        }
    }

    func testEmptyHistoryEntryAndRebuild() {
        let controller = HistoryViewController()
        controller.conversations = []
        controller.loadViewIfNeeded()
        controller.buildContent()
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.contentStack.arrangedSubviews.isEmpty)
    }

    func testHistorySearchWithoutResults() {
        let controller = HistoryViewController()
        controller.loadViewIfNeeded()
        controller.searchField.text = "no matching conversation 400"
        controller.renderConversations()
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.resultsStack.arrangedSubviews.isEmpty)
    }

    func testCommunityEmptyAndFailureStates() {
        let controller = CommunityViewController()
        controller.loadViewIfNeeded()
        controller.selectBoard("no matching board 400")
        controller.view.layoutIfNeeded()
        XCTAssertNotNil(controller.view.findView(identifier: "community-empty-state"))
        controller.showLoadError()
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.postStack.arrangedSubviews.isEmpty)
    }

    func testCommunitySearchWithoutResults() {
        let controller = CommunitySearchViewController()
        controller.loadViewIfNeeded()
        controller.renderResults(for: "no matching post 400")
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.resultsStack.arrangedSubviews.isEmpty)
    }

    func testDeletedPostLayout() {
        let post = CommunityPost(grade: "전체", title: "삭제됨", body: "", time: "", comments: 0,
                                 likes: 0, category: "질문")
        let controller = CommunityPostDetailViewController(post: post)
        XCTAssertFalse(controller.shouldSimulateCommentFailure)
        controller.loadViewIfNeeded()
        controller.showDeletedPostState()
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.contentStack.arrangedSubviews.isEmpty)
    }

    func testMyActivityEmptyLayout() {
        let controller = MyActivityViewController()
        controller.loadViewIfNeeded()
        controller.addPostsEmptyState()
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.itemsStack.arrangedSubviews.isEmpty)
    }

    func testNotificationEmptyLayout() {
        let controller = NotificationsViewController()
        controller.loadViewIfNeeded()
        controller.addEmptyState()
        controller.view.layoutIfNeeded()
        XCTAssertFalse(controller.contentStack.arrangedSubviews.isEmpty)
    }

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

    func testNewConversationGreetingLayout() {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        controller.view.layoutIfNeeded()
        XCTAssertGreaterThan(controller.messagesStack.arrangedSubviews.count, 1)
        controller.networkMonitor.cancel()
    }

    func testChatAttachmentLimitsMatchServerDefaults() {
        XCTAssertNoThrow(try ChatAttachmentPolicy.validateCount(3))
        XCTAssertThrowsError(try ChatAttachmentPolicy.validateCount(4)) {
            XCTAssertEqual($0 as? ChatAttachmentLimitError, .tooManyAttachments)
        }

        XCTAssertNoThrow(try ChatAttachmentPolicy.validateFileSize(5_242_880))
        XCTAssertThrowsError(try ChatAttachmentPolicy.validateFileSize(5_242_881)) {
            XCTAssertEqual($0 as? ChatAttachmentLimitError, .fileTooLarge)
        }
        XCTAssertNoThrow(try ChatAttachmentPolicy.validateTotalSize(12_582_912))
        XCTAssertThrowsError(try ChatAttachmentPolicy.validateTotalSize(12_582_913)) {
            XCTAssertEqual($0 as? ChatAttachmentLimitError, .totalTooLarge)
        }

        XCTAssertNoThrow(try ChatAttachmentPolicy.validatePDFPages(50))
        XCTAssertThrowsError(try ChatAttachmentPolicy.validatePDFPages(51)) {
            XCTAssertEqual($0 as? ChatAttachmentLimitError, .tooManyPDFPages)
        }
        XCTAssertNoThrow(try ChatAttachmentPolicy.validateImageDimensions(width: 5_000, height: 5_000))
        XCTAssertThrowsError(try ChatAttachmentPolicy.validateImageDimensions(width: 5_001, height: 5_000)) {
            XCTAssertEqual($0 as? ChatAttachmentLimitError, .imageTooLarge)
        }
    }

    func testAttachmentTrayMatchesFigmaKeyboardHeight() {
        let tray = ChatAttachmentTrayView()
        var heights: [CGFloat] = []
        tray.onPreferredHeightChange = { heights.append($0) }
        tray.attachments = [
            ChatAttachmentItem(fileName: "사진.png", image: UIImage()),
            ChatAttachmentItem(fileName: "첫번째.pdf", image: nil, url: URL(fileURLWithPath: "/tmp/first.pdf"))
        ]

        XCTAssertEqual(heights.last ?? 0, 225, accuracy: 0.5)
        tray.frame = CGRect(x: 0, y: 0, width: 402, height: 225)
        tray.layoutIfNeeded()
        let attachmentScroll = tray.findView(identifier: "chat-attachment-scroll")
        let imageCard = tray.findView(identifier: "chat-attachment-image-card")
        let documentCard = tray.findView(identifier: "chat-attachment-document-card")
        let questionInputContainer = tray.findView(identifier: "chat-attachment-question-container")
        XCTAssertEqual(attachmentScroll?.frame.height ?? 0, 78, accuracy: 0.5)
        XCTAssertEqual(imageCard?.frame.width ?? 0, 72, accuracy: 0.5)
        XCTAssertEqual(imageCard?.frame.height ?? 0, 72, accuracy: 0.5)
        XCTAssertEqual(documentCard?.frame.height ?? 0, 72, accuracy: 0.5)
        XCTAssertEqual(documentCard?.frame.width ?? 0, 276, accuracy: 0.5)
        XCTAssertEqual(questionInputContainer?.frame.height ?? 0, 52, accuracy: 0.5)

        tray.setKeyboardVisible(true)
        XCTAssertEqual(heights.last ?? 0, 196, accuracy: 0.5)
        tray.frame = CGRect(x: 0, y: 0, width: 402, height: 196)
        tray.layoutIfNeeded()

        XCTAssertEqual(attachmentScroll?.frame.height ?? 0, 70, accuracy: 0.5)
        XCTAssertEqual(imageCard?.frame.width ?? 0, 64, accuracy: 0.5)
        XCTAssertEqual(imageCard?.frame.height ?? 0, 64, accuracy: 0.5)
        XCTAssertEqual(documentCard?.frame.height ?? 0, 64, accuracy: 0.5)
        XCTAssertEqual(documentCard?.frame.width ?? 0, 284, accuracy: 0.5)
        XCTAssertEqual(questionInputContainer?.frame.height ?? 0, 52, accuracy: 0.5)

        tray.setKeyboardVisible(false)
        XCTAssertEqual(heights.last ?? 0, 225, accuracy: 0.5)
    }

    func testAttachmentQuestionInputUsesFigmaFocusBorder() {
        let tray = ChatAttachmentTrayView()
        guard let input = tray.findView(identifier: "chat-attachment-question-input") as? UITextField,
              let inputContainer = input.superview else {
            return XCTFail("첨부 질문 입력창이 트레이에 있어야 합니다")
        }

        tray.textFieldDidBeginEditing(input)
        XCTAssertEqual(inputContainer.layer.borderColor, ChatDetailPalette.brandBorder.cgColor)
        tray.textFieldDidEndEditing(input)
        XCTAssertEqual(inputContainer.layer.borderColor, ChatDetailPalette.border.cgColor)
    }
}

private extension UIView {
    func findView(identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier { return self }
        return subviews.lazy.compactMap { $0.findView(identifier: identifier) }.first
    }
}
