import UIKit

extension CommunityPost {
    func withCommentCount(_ count: Int) -> CommunityPost {
        var updated = CommunityPost(grade: grade, title: title, body: body, time: time,
            comments: count, likes: likes, category: category, detailBody: detailBody, authorCohort: authorCohort)
        updated.id = id
        updated.boardID = boardID
        updated.isMine = isMine
        updated.likedByMe = likedByMe
        return updated
    }
}

@MainActor
extension CommunityPostDetailViewController {
    func loadPostDetail() {
        guard let id = post.id, CommunityPostStore.shared.isServerBacked else { return }
        bodyLabel?.text = "게시글을 불러오는 중이에요…"
        postMoreButton?.isEnabled = false
        Task { [weak self] in
            do {
                let dto = try await CommunityAPI.post(id: id)
                guard let self else { return }
                let boards = CommunityPostStore.shared.boards
                let names = Dictionary(boards.map { ($0.id, CommunityPostStore.boardName($0)) }) { first, _ in first }
                self.applyServerPost(CommunityPostStore.post(from: dto, boardNames: names))
            } catch {
                self?.showDetailRetry(message: "게시글을 불러오지 못했어요") { [weak self] in
                    self?.loadPostDetail()
                }
            }
        }
    }

    func applyServerPost(_ updated: CommunityPost) {
        post = updated
        titleLabel?.text = updated.title
        bodyLabel?.text = updated.detailBody ?? updated.body
        gradeBadgeLabel?.text = updated.grade
        boardSubtitleLabel?.text = "\(updated.grade) 게시판"
        likes = updated.likes
        liked = updated.likedByMe
        visibleCommentCount = updated.comments
        applyLikeAppearance()
        updateCommentCount()
        postMoreButton?.isEnabled = true
    }

    func loadServerComments(postID: Int64) {
        Task { [weak self] in
            do {
                let page = try await CommunityAPI.comments(postID: postID)
                guard let self else { return }
                self.commentStack.arrangedSubviews.forEach {
                    self.commentStack.removeArrangedSubview($0)
                    $0.removeFromSuperview()
                }
                for comment in page.items {
                    self.addComment(author: comment.isMine ? "익명 (나)" : "익명",
                        time: CommunityAPI.relativeTime(comment.createdAt), text: comment.content,
                        commentID: comment.id)
                }
            } catch {
                self?.showDetailRetry(message: "댓글을 불러오지 못했어요") { [weak self] in
                    self?.loadServerComments(postID: postID)
                }
            }
        }
    }

    private func showDetailRetry(message: String, retry: @escaping () -> Void) {
        let button = AppStyle.button("\(message). 다시 시도", primary: false) { retry() }
        button.addAction(UIAction { [weak button] _ in button?.removeFromSuperview() }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
    }
}
