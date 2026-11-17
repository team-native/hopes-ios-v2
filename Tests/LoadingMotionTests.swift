import XCTest
@testable import Hopes

@MainActor
final class LoadingMotionTests: XCTestCase {
    func testSkeletonBarsPulseWhileLoading() throws {
        try XCTSkipIf(!AppLoadingMotion.isEnabled)
        let card = CommunityViewController.makeSkeletonCard()
        let bars = card.subviews.first?.subviews ?? []
        XCTAssertEqual(bars.count, 4)
        XCTAssertTrue(bars.allSatisfy { $0.layer.animation(forKey: AppLoadingMotion.pulseKey) != nil })
    }

    func testDotsBounceInSequence() throws {
        try XCTSkipIf(!AppLoadingMotion.isEnabled)
        let dots = (0..<3).map { _ in UIView() }
        AppLoadingMotion.bounce(dots)
        let begins = dots.compactMap { $0.layer.animation(forKey: AppLoadingMotion.bounceKey)?.beginTime }
        XCTAssertEqual(begins.count, 3)
        XCTAssertLessThan(begins[0], begins[1])
        XCTAssertLessThan(begins[1], begins[2])
    }
}
