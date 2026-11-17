import XCTest
@testable import Hopes

@MainActor
final class CommunityBindingTests: XCTestCase {
    func testCommentCountUpdatePreservesServerIdentityAndOwnership() {
        var post = CommunityPost(grade: "10기", title: "제목", body: "미리보기", time: "방금",
            comments: 2, likes: 4, category: "질문", detailBody: "전체 본문")
        post.id = 123
        post.boardID = 8
        post.isMine = true
        post.likedByMe = true
        let updated = post.withCommentCount(3)
        XCTAssertEqual(updated.id, 123)
        XCTAssertEqual(updated.boardID, 8)
        XCTAssertTrue(updated.isMine)
        XCTAssertTrue(updated.likedByMe)
        XCTAssertEqual(updated.comments, 3)
        XCTAssertEqual(updated.detailBody, "전체 본문")
    }

    func testSwaggerDetailBindsFullBodyAndOwnPostActions() throws {
        let json = #"""
        {"id":123,"boardId":8,"title":"전체 제목","content":"전체 본문",
        "createdAt":"2026-11-17T09:00:00Z","likeCount":4,"commentCount":0,"likedByMe":true,"isMine":true}
        """#
        let dto = try JSONDecoder().decode(PostPreviewDTO.self, from: Data(json.utf8))
        let post = CommunityPostStore.post(from: dto, boardNames: [8: "10기"])
        let controller = CommunityPostDetailViewController(post: post)
        controller.loadViewIfNeeded()
        controller.applyServerPost(post)
        XCTAssertTrue(controller.isMine)
        XCTAssertEqual(controller.bodyLabel?.text, "전체 본문")
        XCTAssertEqual(controller.visibleCommentCount, 0)
        XCTAssertTrue(controller.liked)
        XCTAssertEqual(controller.post.id, 123)
    }
}
