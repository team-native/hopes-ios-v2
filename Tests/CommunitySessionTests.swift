import XCTest
@testable import Hopes

@MainActor
final class CommunitySessionTests: XCTestCase {
    func testNewSessionClearsPreviousUserData() {
        let store = CommunityPostStore.shared
        store.myPosts = [CommunityPost(grade: "10기", title: "이전 사용자 글", body: "", time: "", comments: 0, likes: 0,
            category: "질문")]
        store.reportedCommentIDs = [1]
        store.markLoadedFromServer()

        store.resetForNewSession()

        XCTAssertTrue(store.posts.isEmpty)
        XCTAssertTrue(store.myPosts.isEmpty)
        XCTAssertTrue(store.myComments.isEmpty)
        XCTAssertTrue(store.reportedCommentIDs.isEmpty)
        XCTAssertFalse(store.hasLoadedFromServer)
    }

    func testSkeletonCardMatchesFigmaShape() {
        let card = CommunityViewController.makeSkeletonCard()
        card.layoutIfNeeded()
        XCTAssertEqual(card.layer.cornerRadius, 22)
        XCTAssertEqual(card.subviews.first?.subviews.count, 4)
    }
}
