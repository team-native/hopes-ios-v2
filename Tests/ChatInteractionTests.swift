import XCTest
@testable import Hopes

@MainActor
final class ChatInteractionTests: XCTestCase {
    func testAnswerLikesAreIndependentAndFollowUpStartsUnselected() throws {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        defer { controller.releaseResources() }
        controller.addAnswerActions()
        controller.addAnswerActions()
        let rows = controller.messagesStack.arrangedSubviews.compactMap { $0 as? UIStackView }
            .filter { $0.arrangedSubviews.first?.accessibilityIdentifier == "answer-like" }
        let first = try XCTUnwrap(rows.first?.arrangedSubviews.first as? UIButton)
        let second = try XCTUnwrap(rows.last?.arrangedSubviews.first as? UIButton)
        XCTAssertFalse(first.isSelected)
        XCTAssertFalse(second.isSelected)
        first.sendActions(for: .touchUpInside)
        XCTAssertTrue(first.isSelected)
        XCTAssertFalse(second.isSelected)
        XCTAssertEqual((rows.last?.arrangedSubviews[1] as? UIButton)?.configuration?.background.backgroundColor, .white)
    }

    func testRelatedQuestionContentDoesNotInterceptTouchesOrSendWhileBusy() throws {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        defer { controller.releaseResources() }
        controller.addRelatedQuestions(["질문 테스트"])
        let card = try XCTUnwrap(controller.messagesStack.arrangedSubviews.last)
        let stack = try XCTUnwrap(card.subviews.first as? UIStackView)
        let button = try XCTUnwrap(stack.arrangedSubviews.compactMap { $0 as? UIButton }.first)
        XCTAssertFalse(try XCTUnwrap(button.subviews.first as? UIStackView).isUserInteractionEnabled)
        controller.inputField.isEnabled = false
        button.sendActions(for: .touchUpInside)
        XCTAssertTrue(controller.inputField.text?.isEmpty ?? true)
        XCTAssertNil(controller.pendingAnswerCard)
    }

    func testHeaderStaysOutsideScrollAndViewportTracksLatestMessage() {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        defer { controller.releaseResources() }
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        for _ in 0..<15 { controller.addMessage("테스트 메시지", outgoing: false) }
        controller.scrollToLatestMessage()
        XCTAssertEqual(controller.conversationHeaderTitleLabel?.superview?.superview?.superview, controller.view)
        XCTAssertGreaterThan(controller.scrollView.contentOffset.y, 0)
        let expected = controller.scrollView.contentSize.height - controller.scrollView.bounds.height
            + controller.scrollView.adjustedContentInset.bottom
        XCTAssertEqual(controller.scrollView.contentOffset.y, expected, accuracy: 1)
    }
}
