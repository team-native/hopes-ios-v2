import XCTest
@testable import Hopes

@MainActor
final class ScreenEntryTests: XCTestCase {
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

    func testNewConversationGreetingLayout() {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        controller.view.layoutIfNeeded()
        XCTAssertGreaterThan(controller.messagesStack.arrangedSubviews.count, 1)
        controller.networkMonitor.cancel()
    }
}

private extension UIView {
    func findView(identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier { return self }
        return subviews.lazy.compactMap { $0.findView(identifier: identifier) }.first
    }
}
