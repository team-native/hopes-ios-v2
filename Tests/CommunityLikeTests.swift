import XCTest
@testable import Hopes

@MainActor
final class CommunityLikeTests: CommunityStoreTestCase {
    private func post(likedByMe: Bool) -> CommunityPost {
        var post = CommunityPost(grade: "10기", title: "좋아요 테스트", body: "본문", time: "방금", comments: 0, likes: 12,
            category: "질문")
        post.likedByMe = likedByMe
        return post
    }

    func testServerLikedPostStartsInLikedFigmaStyle() {
        let controller = CommunityPostDetailViewController(post: post(likedByMe: true))
        CommunityPostStore.shared.posts.append(controller.post)
        controller.loadViewIfNeeded()
        XCTAssertTrue(controller.liked)
        XCTAssertEqual(controller.likeButton.backgroundColor, AppStyle.blue)
        XCTAssertEqual(controller.likeButton.titleColor(for: .normal), .white)
    }

    func testTogglingLikedPostUnlikesAndRestoresSoftStyle() {
        let controller = CommunityPostDetailViewController(post: post(likedByMe: true))
        CommunityPostStore.shared.posts.append(controller.post)
        controller.loadViewIfNeeded()
        controller.toggleLike()
        XCTAssertFalse(controller.liked)
        XCTAssertEqual(controller.likes, 11)
        XCTAssertEqual(controller.likeButton.titleColor(for: .normal), AppStyle.blue)
    }
}
