import XCTest
@testable import Hopes

@MainActor
final class CountUpTests: XCTestCase {
    func testCountUpEasesFromStartToTarget() {
        XCTAssertEqual(AppCountUpAnimator.value(from: 0, to: 10, progress: 0), 0)
        XCTAssertEqual(AppCountUpAnimator.value(from: 0, to: 10, progress: 1), 10)
        XCTAssertEqual(AppCountUpAnimator.value(from: 0, to: 10, progress: 2), 10)
        XCTAssertGreaterThan(AppCountUpAnimator.value(from: 0, to: 100, progress: 0.5), 50)
        XCTAssertEqual(AppCountUpAnimator.value(from: 7, to: 3, progress: 1), 3)
    }

    func testSettingValueKeepsLabelStyle() {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: "0", attributes: [.kern: -0.3])
        AppCountUpAnimator.setValue(12, on: label)
        XCTAssertEqual(label.attributedText?.string, "12")
        XCTAssertEqual(label.attributedText?.attribute(.kern, at: 0, effectiveRange: nil) as? Double, -0.3)
    }
}
