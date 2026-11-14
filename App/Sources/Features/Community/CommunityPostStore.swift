import Foundation

struct CommunityComment {
    let board: String
    let postTitle: String
    let text: String
    let time: String
}

@MainActor
final class CommunityPostStore {
    static let shared = CommunityPostStore()

    private(set) var posts = [
        CommunityPost(grade: "10기", title: "기숙사 와이파이 다들 잘 돼?", body: "3층 끝방인데 저녁만 되면 너무 느려져서… 다른 층은 어떤지 궁금해.",
            time: "10분 전", comments: 5, likes: 12, category: "질문",
                detailBody: "3층 끝방인데 저녁만 되면 와이파이가 너무 느려져서 과제 제출이 힘들어. 다른 층은 어떤지, 해결 방법 아는 사람 있으면 알려줘!"),
        CommunityPost(grade: "10기", title: "전공 동아리 면접 후기 공유", body: "어제 보고 왔는데 생각보다 분위기 편했어. 질문은 주로 지원 동기 위주였음.",
            time: "1시간 전", comments: 9, likes: 34, category: "정보"),
        CommunityPost(grade: "9기", title: "취업 준비 언제부터 시작했어?", body: "2학년 여름방학부터 포트폴리오 만들기 시작했는데 늦은 건지 모르겠어.",
            time: "3시간 전", comments: 14, likes: 21, category: "질문"),
        CommunityPost(grade: "10기", title: "기숙사 세탁실 이용 시간 아는 사람?", body: "주말에도 밤 10시까지 쓸 수 있는지 궁금해.", time: "어제",
            comments: 2, likes: 4, category: "질문")
    ]

    private(set) var myPosts = [
        CommunityPost(grade: "10기", title: "기숙사 와이파이 다들 잘 돼?", body: "3층 끝방인데 저녁만 되면 너무 느려져서… 다른 층은 어떤지 궁금해.",
            time: "10분 전", comments: 5, likes: 12, category: "질문"),
        CommunityPost(grade: "10기", title: "기숙사 세탁실 이용 시간 아는 사람?", body: "주말에도 밤 10시까지 쓸 수 있는지 궁금해.", time: "어제",
            comments: 2, likes: 4, category: "질문")
    ]

    private(set) var myComments = [
        CommunityComment(board: "10기", postTitle: "기숙사 와이파이 다들 잘 돼?", text: "오 고마워, 내일 말씀드려 볼게.", time: "방금"),
        CommunityComment(board: "전체", postTitle: "전공 동아리 면접 후기 공유", text: "혹시 포트폴리오도 봤어?", time: "2시간 전"),
        CommunityComment(board: "9기", postTitle: "취업 준비 언제부터 시작했어?", text: "저는 2학년 겨울부터 했어요!", time: "어제"),
        CommunityComment(board: "전체", postTitle: "시험 기간 공부 장소 추천해줘", text: "도서관 스터디룸이 조용하고 좋아요.", time: "3일 전"),
        CommunityComment(board: "10기", postTitle: "전공 프로젝트 준비 팁", text: "작게라도 먼저 만들어보는 걸 추천해요.", time: "지난주")
    ]
    private var shouldShowPublishedToast = false

    private init() {}

    func markPostPublished() {
        shouldShowPublishedToast = true
    }

    func consumePublishedToast() -> Bool {
        defer { shouldShowPublishedToast = false }
        return shouldShowPublishedToast
    }

    func add(title: String, body: String, category: String, grade: String) {
        let newPost = CommunityPost(
            grade: grade,
            title: title,
            body: body,
            time: "방금 전",
            comments: 0,
            likes: 0,
            category: category
        )
        posts.insert(newPost, at: 0)
        myPosts.insert(newPost, at: 0)
    }

    func addComment(postTitle: String, text: String) {
        let board = posts.first(where: { $0.title == postTitle })?.grade ?? "전체"
        myComments.insert(CommunityComment(board: board, postTitle: postTitle, text: text, time: "방금"), at: 0)
    }

    func update(_ original: CommunityPost, title: String, body: String, grade: String) -> CommunityPost {
        let updated = CommunityPost(
            grade: grade,
            title: title,
            body: body,
            time: original.time,
            comments: original.comments,
            likes: original.likes,
            category: original.category,
            detailBody: body == original.body ? original.detailBody : nil
        )
        posts = posts.map { $0.title == original.title && $0.body == original.body ? updated : $0 }
        myPosts = myPosts.map { $0.title == original.title && $0.body == original.body ? updated : $0 }
        return updated
    }

    func updateComment(postTitle: String, oldText: String, newText: String) {
        guard let index = myComments.firstIndex(where: { $0.postTitle == postTitle && $0.text == oldText }) else {
            let board = posts.first(where: { $0.title == postTitle })?.grade ?? "전체"
            myComments.insert(CommunityComment(board: board, postTitle: postTitle, text: newText, time: "방금"), at: 0)
            return
        }
        let comment = myComments[index]
        myComments[index] = CommunityComment(board: comment.board, postTitle: comment.postTitle, text: newText,
            time: comment.time)
    }

    @discardableResult
    func deleteComment(postTitle: String, text: String) -> Bool {
        guard let index = myComments.firstIndex(where: {
            $0.postTitle == postTitle && $0.text == text
        }) else { return false }
        myComments.remove(at: index)
        posts = posts.map { post in
            guard post.title == postTitle else { return post }
            return CommunityPost(grade: post.grade, title: post.title, body: post.body, time: post.time,
                comments: max(0, post.comments - 1), likes: post.likes, category: post.category,
                    detailBody: post.detailBody)
        }
        myPosts = myPosts.map { post in
            guard post.title == postTitle else { return post }
            return CommunityPost(grade: post.grade, title: post.title, body: post.body, time: post.time,
                comments: max(0, post.comments - 1), likes: post.likes, category: post.category,
                    detailBody: post.detailBody)
        }
        return true
    }

    func delete(_ post: CommunityPost) {
        posts.removeAll { $0.title == post.title && $0.body == post.body }
        myPosts.removeAll { $0.title == post.title && $0.body == post.body }
        myComments.removeAll { $0.postTitle == post.title }
    }
}
