import XCTest
@testable import Hopes

@MainActor
final class HomePopularTests: XCTestCase {
    func testPopularRowPinsLikeCountToTrailingEdgeLikeFigma() {
        let style = HomePopularRowStyle(blue: .blue, softBlue: .white, tertiary: .gray, border: .gray)
        let row = HomePopularRowFactory.make(cohort: "전체", title: "전공 동아리 면접 후기 공유", likes: "34",
            style: style) {}
        row.translatesAutoresizingMaskIntoConstraints = false
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 362, height: 100))
        host.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            row.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutIfNeeded()
        let stack = try? XCTUnwrap(row.subviews.first as? UIStackView)
        let stats = stack?.arrangedSubviews.last
        XCTAssertEqual(stats.map { $0.frame.maxX } ?? 0, 345, accuracy: 0.5)
        XCTAssertEqual(stack?.arrangedSubviews[1].frame.minX ?? 0, 70, accuracy: 0.5)
        XCTAssertEqual(row.frame.height, 54, accuracy: 0.5)
    }

    func testTopPopularPostsSortByLikesKeepingServerOrderForTies() {
        let posts = [("a", 3), ("b", 10), ("c", 3), ("d", 7)].map {
            CommunityPost(grade: "전체", title: $0.0, body: "", time: "", comments: 0, likes: $0.1, category: "질문")
        }
        XCTAssertEqual(HomePopularItem.top(from: posts).map(\.title), ["b", "d"])
        XCTAssertEqual(HomePopularItem.top(from: Array(posts.prefix(1))).map(\.title), ["a"])
        XCTAssertTrue(HomePopularItem.top(from: []).isEmpty)
    }

    func testFailedStateMatchesFigmaByHidingTipsAndShowingRetry() {
        let controller = HomeViewController()
        controller.loadViewIfNeeded()
        controller.renderPopular(.failed)
        XCTAssertEqual(controller.tipsSection?.isHidden, true)
        controller.renderPopular(.loaded)
        XCTAssertEqual(controller.tipsSection?.isHidden, false)
        XCTAssertFalse(controller.popularSection.isHidden)
    }

    func testGreetingUsesGivenNameOnlyForKoreanFullNames() {
        XCTAssertEqual(HomeViewController.greetingName(for: "임서하"), "서하")
        XCTAssertEqual(HomeViewController.greetingName(for: "Hopes 사용자"), "Hopes 사용자")
        XCTAssertEqual(HomeViewController.greetingName(for: "남궁민수"), "남궁민수")
    }
}
