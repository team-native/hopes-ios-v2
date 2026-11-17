import XCTest
@testable import Hopes

@MainActor
final class HomeActionTests: XCTestCase {
    private func layout(_ row: UIView) -> UIView {
        row.translatesAutoresizingMaskIntoConstraints = false
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 362, height: 100))
        host.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            row.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutIfNeeded()
        return host
    }

    func testPopularRowTitleAndHeartReceiveTouches() {
        let style = HomePopularRowStyle(blue: .blue, softBlue: .white, tertiary: .gray, border: .gray)
        let row = HomePopularRowFactory.make(cohort: "전체", title: "인기글", likes: "3", style: style,
            onLike: {}, action: {})
        let host = layout(row)
        let titlePoint = CGPoint(x: 120, y: row.frame.midY)
        XCTAssertEqual(host.hitTest(titlePoint, with: nil)?.accessibilityIdentifier, "home-popular-row")
        let heartPoint = CGPoint(x: row.frame.maxX - 20, y: row.frame.midY)
        XCTAssertEqual(host.hitTest(heartPoint, with: nil)?.accessibilityIdentifier, "home-popular-like")
    }

    func testTogglingPopularLikeUpdatesCountAndState() {
        var item = HomePopularItem(board: "전체", title: "인기글", likes: 3, post: nil)
        item.toggleLike()
        XCTAssertTrue(item.liked)
        XCTAssertEqual(item.likes, 4)
        item.toggleLike()
        XCTAssertFalse(item.liked)
        XCTAssertEqual(item.likes, 3)
    }

    func testTipCardIsTappable() {
        let style = HomePopularRowStyle(blue: .blue, softBlue: .white, tertiary: .gray, border: .gray)
        var tapped = false
        let card = HomeTipRowFactory.make(number: "1", caption: "질문 전에,", text: "학과·전공을 먼저 골라요",
            style: style) { tapped = true }
        let host = layout(card)
        let target = host.hitTest(CGPoint(x: 150, y: 36), with: nil) as? UIButton
        XCTAssertEqual(target?.accessibilityIdentifier, "home-tip-1")
        target?.sendActions(for: .touchUpInside)
        XCTAssertTrue(tapped)
    }
}
