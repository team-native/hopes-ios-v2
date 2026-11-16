import XCTest
@testable import Hopes

@MainActor
final class LifecycleTests: XCTestCase {
    func testCountdownUsesWallClockSoBackgroundTimeIsCounted() {
        let start = Date(timeIntervalSince1970: 1_000)
        let deadline = AuthCountdown.deadline(from: start)
        XCTAssertEqual(AuthCountdown.remainingSeconds(until: deadline, now: start), 300)
        XCTAssertEqual(AuthCountdown.remainingSeconds(until: deadline, now: start.addingTimeInterval(125)), 175)
        XCTAssertEqual(AuthCountdown.remainingSeconds(until: deadline, now: start.addingTimeInterval(299.4)), 1)
        XCTAssertEqual(AuthCountdown.remainingSeconds(until: deadline, now: start.addingTimeInterval(400)), 0)
    }

    func testLeavingChatCancelsInFlightAnswer() {
        let controller = ChatConversationViewController(question: nil)
        controller.loadViewIfNeeded()
        let task = Task<Void, Never> { try? await Task.sleep(for: .seconds(30)) }
        controller.answerTask = task
        controller.releaseResources()
        XCTAssertTrue(task.isCancelled)
        XCTAssertNil(controller.answerTask)
    }
}
