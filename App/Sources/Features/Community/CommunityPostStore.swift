import Foundation

struct CommunityComment {
    let postTitle: String
    let text: String
    let time: String
}

@MainActor
final class CommunityPostStore {
    static let shared = CommunityPostStore()

    private(set) var posts = [
        CommunityPost(grade: "10기", title: "기숙사 와이파이 다들 잘 돼?", body: "3층 끝방인데 저녁만 되면 너무 느려져서… 다른 층은 어떤지 궁금해.", time: "10분 전", comments: 12, likes: 5, category: "질문"),
        CommunityPost(grade: "10기", title: "전공 동아리 면접 후기 공유", body: "어제 보고 왔는데 생각보다 분위기 편했어. 질문은 주로 지원 동기 위주였음.", time: "1시간 전", comments: 34, likes: 9, category: "정보"),
        CommunityPost(grade: "9기", title: "취업 준비 언제부터 시작했어?", body: "2학년 여름방학부터 포트폴리오 만들기 시작했는데 늦은 건지 모르겠어.", time: "3시간 전", comments: 21, likes: 14, category: "질문")
    ]

    private(set) var myPosts = [
        CommunityPost(grade: "익명", title: "시험 기간 공부 장소 추천해줘", body: "도서관 말고 집중 잘 되는 장소가 있을까?", time: "2일 전", comments: 4, likes: 2, category: "질문"),
        CommunityPost(grade: "익명", title: "전공 프로젝트 준비 팁", body: "첫 프로젝트를 시작할 때 참고하면 좋을 팁이 궁금해.", time: "지난주", comments: 3, likes: 6, category: "정보")
    ]

    private(set) var myComments = [
        CommunityComment(postTitle: "기숙사 와이파이 다들 잘 돼?", text: "공유기 위치에 따라서 신호가 조금 다를 수 있어요", time: "오늘")
    ]

    private init() {}

    func add(title: String, body: String, category: String, anonymous: Bool) {
        let newPost = CommunityPost(
            grade: anonymous ? "익명" : "10기",
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
        myComments.insert(CommunityComment(postTitle: postTitle, text: text, time: "방금 전"), at: 0)
    }
}
