import Foundation

struct BoardDTO: Decodable {
    let id: Int64
    let name: String
    let cohort: Int?
}

struct PostPreviewDTO: Decodable {
    let id: Int64
    let boardId: Int64
    let title: String
    let preview: String?
    let content: String?
    let createdAt: String
    let likeCount: Int
    let commentCount: Int
    let likedByMe: Bool
    let isMine: Bool
}

struct CommentDTO: Decodable {
    let id: Int64
    let content: String
    let createdAt: String
    let isMine: Bool
}

struct MyCommentDTO: Decodable {
    let id: Int64
    let postId: Int64
    let postTitle: String?
    let content: String
    let createdAt: String
}

struct ItemsDTO<Item: Decodable>: Decodable {
    let items: [Item]
}

struct PageDTO<Item: Decodable>: Decodable {
    let items: [Item]
    let hasNext: Bool
}

struct CreatePostPayload: Encodable {
    let boardId: Int64
    let title: String
    let content: String
    let clientRequestId: String
}

struct ReportPayload: Encodable {
    let targetType: String
    let targetId: Int64
    let reasonCode: String
}

enum CommunityAPI {
    private static var client: APIClient { .shared }
    private static let base = "/api/community"

    static func boards() async throws -> [BoardDTO] {
        let response: ItemsDTO<BoardDTO> = try await client.send("GET", "\(base)/boards", authenticated: true)
        return response.items
    }

    static func posts() async throws -> PageDTO<PostPreviewDTO> {
        try await client.send("GET", "\(base)/posts?page=0&size=100", authenticated: true)
    }

    static func myPosts() async throws -> PageDTO<PostPreviewDTO> {
        try await client.send("GET", "\(base)/me/posts?page=0&size=100", authenticated: true)
    }

    static func myComments() async throws -> PageDTO<MyCommentDTO> {
        try await client.send("GET", "\(base)/me/comments?page=0&size=100", authenticated: true)
    }

    static func comments(postID: Int64) async throws -> PageDTO<CommentDTO> {
        try await client.send("GET", "\(base)/posts/\(postID)/comments?page=0&size=100", authenticated: true)
    }

    static func createPost(boardID: Int64, title: String, content: String) async throws {
        let payload = CreatePostPayload(
            boardId: boardID, title: title, content: content, clientRequestId: UUID().uuidString
        )
        try await client.send("POST", "\(base)/posts", body: payload, authenticated: true)
    }

    static func updatePost(id: Int64, title: String, content: String) async throws {
        let body = ["title": title, "content": content]
        try await client.send("PATCH", "\(base)/posts/\(id)", body: body, authenticated: true)
    }

    static func deletePost(id: Int64) async throws {
        try await client.send("DELETE", "\(base)/posts/\(id)", authenticated: true)
    }

    static func addComment(postID: Int64, content: String) async throws {
        let body = ["content": content, "clientRequestId": UUID().uuidString]
        try await client.send("POST", "\(base)/posts/\(postID)/comments", body: body, authenticated: true)
    }

    static func updateComment(id: Int64, content: String) async throws {
        try await client.send("PATCH", "\(base)/comments/\(id)", body: ["content": content], authenticated: true)
    }

    static func deleteComment(id: Int64) async throws {
        try await client.send("DELETE", "\(base)/comments/\(id)", authenticated: true)
    }

    static func setLike(postID: Int64, liked: Bool) async throws {
        try await client.send(liked ? "PUT" : "DELETE", "\(base)/posts/\(postID)/like", authenticated: true)
    }

    static func report(postID: Int64, reasonCode: String) async throws {
        try await report(targetType: "POST", targetID: postID, reasonCode: reasonCode)
    }

    static func reportComment(id: Int64, reasonCode: String) async throws {
        try await report(targetType: "COMMENT", targetID: id, reasonCode: reasonCode)
    }

    private static func report(targetType: String, targetID: Int64, reasonCode: String) async throws {
        let payload = ReportPayload(targetType: targetType, targetId: targetID, reasonCode: reasonCode)
        try await client.send("POST", "\(base)/reports", body: payload, authenticated: true)
    }

    static func relativeTime(_ value: String) -> String {
        guard let date = ChatAPI.date(from: value) else { return "" }
        let seconds = Int(Date().timeIntervalSince(date))
        switch seconds {
        case ..<60: return "방금 전"
        case ..<3600: return "\(seconds / 60)분 전"
        case ..<86_400: return "\(seconds / 3600)시간 전"
        case ..<172_800: return "어제"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일"
            return formatter.string(from: date)
        }
    }
}
