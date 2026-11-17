import XCTest
@testable import Hopes

@MainActor
final class ChatRecommendationTapTests: XCTestCase {
    func testRecommendationCardTouchStartsConversation() throws {
        let chat = ChatHomeViewController()
        let navigation = UINavigationController(rootViewController: chat)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        let card = chat.makeQuestionCard(iconName: "chat-question-bed-icon", question: "기숙사 하루 일과가 어떻게 돼?")
        card.frame = CGRect(x: 0, y: 0, width: 362, height: 62)
        card.layoutIfNeeded()
        let hit = card.hitTest(CGPoint(x: 120, y: 31), with: nil)
        XCTAssertTrue(hit === card, "card content must not swallow touches")
        (card as? UIControl)?.sendActions(for: .touchUpInside)
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        XCTAssertTrue(navigation.topViewController is ChatConversationViewController)
    }
}
