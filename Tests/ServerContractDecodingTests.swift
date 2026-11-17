import XCTest
@testable import Hopes

final class ServerContractDecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    func testBoardsResponseIsWrappedInItems() throws {
        let json = #"{"items":[{"id":1,"name":"전체","cohort":null,"sortOrder":0},"#
            + #"{"id":2,"name":"10기","cohort":10,"sortOrder":10}]}"#
        let response = try decode(ItemsDTO<BoardDTO>.self, json)
        XCTAssertEqual(response.items.map(\.name), ["전체", "10기"])
        XCTAssertEqual(response.items[1].cohort, 10)
    }

    func testCatalogResponseIsWrappedInItems() throws {
        let json = #"{"items":[{"id":3,"name":"인공지능과","description":"","sortOrder":1,"isActive":true}]}"#
        let response = try decode(ItemsDTO<CategoryDTO>.self, json)
        XCTAssertEqual(response.items.first?.id, 3)
    }

    func testPostPageMatchesSwaggerPostPreview() throws {
        let json = """
        {"items":[{"id":7,"boardId":2,"title":"t","preview":"p","createdAt":"2026-11-17T09:00:00Z",
        "updatedAt":"2026-11-17T09:00:00Z","likeCount":3,"commentCount":1,"likedByMe":true,"isMine":false,
        "authorLabel":"10기"}],"page":0,"size":100,"hasNext":false}
        """
        let page = try decode(PageDTO<PostPreviewDTO>.self, json)
        XCTAssertEqual(page.items.first?.likeCount, 3)
        XCTAssertEqual(page.items.first?.likedByMe, true)
    }
}
