import XCTest
@testable import Hopes

@MainActor
final class ChatHomeKeyboardTests: XCTestCase {
    func testKeyboardCollapsesContentToHintAndRestoresHiddenStates() {
        let controller = ChatHomeViewController()
        controller.loadViewIfNeeded()
        let stack = controller.contentStack
        let header = stack.arrangedSubviews[0]
        let hiddenBefore = stack.arrangedSubviews.filter(\.isHidden).map(ObjectIdentifier.init)

        controller.setKeyboardCollapsed(true)
        let visible = stack.arrangedSubviews.filter { !$0.isHidden }
        XCTAssertEqual(visible.count, 2)
        XCTAssertTrue(visible.contains { $0 === header })
        XCTAssertTrue(visible.contains { $0 === controller.keyboardHint })

        controller.setKeyboardCollapsed(false)
        XCTAssertTrue(controller.keyboardHint.isHidden)
        let hiddenAfter = stack.arrangedSubviews.filter { $0 !== controller.keyboardHint && $0.isHidden }
        XCTAssertEqual(hiddenAfter.map(ObjectIdentifier.init), hiddenBefore)
    }

    func testTappingRecommendationFillsInput() {
        let controller = ChatHomeViewController()
        controller.loadViewIfNeeded()
        controller.fillQuestion("기숙사 하루 일과가 어떻게 돼?")
        XCTAssertEqual(controller.messageField.text, "기숙사 하루 일과가 어떻게 돼?")
    }
}

final class MajorChipWrapTests: XCTestCase {
    func testWrapsLikeFigmaOnWideScreenAndAddsRowOnNarrowScreen() {
        let widths: [CGFloat] = [54, 84, 91, 89, 44, 51, 84, 77, 56]
        XCTAssertEqual(MajorPickerViewController.wrapRows(widths: widths, available: 362, spacing: 8),
            [[0, 1, 2, 3], [4, 5, 6, 7, 8]])
        XCTAssertEqual(MajorPickerViewController.wrapRows(widths: widths, available: 300, spacing: 8).count, 3)
        XCTAssertEqual(MajorPickerViewController.wrapRows(widths: [], available: 300, spacing: 8), [])
    }
}
