import Foundation

extension Notification.Name {
    static let communityStoreDidChange = Notification.Name("kr.hs.gsm.hopes.communityStoreDidChange")
}

@MainActor
extension CommunityPostStore {
    var isServerBacked: Bool { AccessTokenStore.shared.hasToken }

    func refresh() async throws {
        guard isServerBacked else { return }
        async let boardList = CommunityAPI.boards()
        async let postPage = CommunityAPI.posts()
        async let minePage = CommunityAPI.myPosts()
        async let commentPage = CommunityAPI.myComments()
        boards = try await boardList
        let names = Dictionary(boards.map { ($0.id, Self.boardName($0)) }) { first, _ in first }
        posts = try await postPage.items.map { Self.post(from: $0, boardNames: names) }
        myPosts = try await minePage.items.map { Self.post(from: $0, boardNames: names) }
        let boardPairs = (posts + myPosts).compactMap { post in post.id.map { ($0, post.grade) } }
        let postBoards = Dictionary(boardPairs) { first, _ in first }
        myComments = try await commentPage.items.map { comment in
            CommunityComment(
                id: comment.id,
                postID: comment.postId,
                board: postBoards[comment.postId] ?? "전체",
                postTitle: comment.postTitle ?? "삭제된 게시글",
                text: comment.content,
                time: CommunityAPI.relativeTime(comment.createdAt)
            )
        }
        markLoadedFromServer()
        NotificationCenter.default.post(name: .communityStoreDidChange, object: nil)
    }

    func boardID(for grade: String) -> Int64? {
        boards.first { Self.boardName($0) == grade }?.id
    }

    func postID(forTitle title: String) -> Int64? {
        (posts + myPosts).first { $0.title == title }?.id
    }

    func commentID(postTitle: String, text: String) -> Int64? {
        myComments.first { $0.postTitle == postTitle && $0.text == text }?.id
    }

    func syncWithServer(_ operation: @escaping @MainActor () async throws -> Void) {
        guard isServerBacked else { return }
        Task { @MainActor in
            try? await operation()
            try? await self.refresh()
        }
    }

    static func boardName(_ board: BoardDTO) -> String {
        board.cohort.map { "\($0)기" } ?? "전체"
    }

    static func post(from dto: PostPreviewDTO, boardNames: [Int64: String]) -> CommunityPost {
        let grade = boardNames[dto.boardId] ?? "전체"
        var post = CommunityPost(
            grade: grade,
            title: dto.title,
            body: dto.preview ?? dto.content ?? "",
            time: CommunityAPI.relativeTime(dto.createdAt),
            comments: dto.commentCount,
            likes: dto.likeCount,
            category: "질문",
            detailBody: dto.content,
            authorCohort: grade
        )
        post.id = dto.id
        post.boardID = dto.boardId
        post.isMine = dto.isMine
        post.likedByMe = dto.likedByMe
        return post
    }
}
