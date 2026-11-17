import UIKit

struct HomePopularItem {
    let board: String
    let title: String
    var likes: Int
    let post: CommunityPost?
    var liked = false

    static let samples = [
        HomePopularItem(board: "전체", title: "전공 동아리 면접 후기 공유", likes: 34, post: nil),
        HomePopularItem(board: "9기", title: "취업 준비 언제부터 시작했어?", likes: 21, post: nil)
    ]

    static func top(from posts: [CommunityPost], limit: Int = 2) -> [HomePopularItem] {
        posts.enumerated()
            .sorted { lhs, rhs in
                lhs.element.likes == rhs.element.likes ? lhs.offset < rhs.offset : lhs.element.likes > rhs.element.likes
            }
            .prefix(limit)
            .map { HomePopularItem(board: $0.element.grade, title: $0.element.title, likes: $0.element.likes,
                post: $0.element, liked: $0.element.likedByMe) }
    }

    mutating func toggleLike() {
        liked.toggle()
        likes = max(0, likes + (liked ? 1 : -1))
    }
}

enum HomePopularState {
    case loading
    case loaded
    case failed
}

@MainActor
extension HomeViewController {
    func installPopularSection() {
        popularSection.axis = .vertical
        popularSection.spacing = 16
        popularSection.accessibilityIdentifier = "home-popular-section"
        contentStack.addArrangedSubview(popularSection)
    }

    func loadPopularPosts() {
        let store = CommunityPostStore.shared
        guard store.isServerBacked, popularTask == nil else { return }
        if popularItems.allSatisfy({ $0.post == nil }) { renderPopular(.loading) }
        popularTask = Task { [weak self] in
            do {
                try await store.refresh()
                guard let self else { return }
                self.popularItems = HomePopularItem.top(from: store.posts)
                self.renderPopular(.loaded)
            } catch {
                self?.renderPopular(.failed)
            }
            self?.popularTask = nil
        }
    }

    func renderPopular(_ state: HomePopularState) {
        popularSection.arrangedSubviews.forEach { view in
            popularSection.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        tipsSection?.isHidden = state == .failed
        popularSection.isHidden = state == .loaded && popularItems.isEmpty
        switch state {
        case .loading:
            popularSection.addArrangedSubview(compactHeader("커뮤니티 인기글"))
            popularSection.addArrangedSubview(HomePreviewStateViews.popularSkeleton())
        case .failed:
            popularSection.addArrangedSubview(compactHeader("커뮤니티 인기글"))
            popularSection.addArrangedSubview(HomePreviewStateViews.popularError(tertiary: tertiary) { [weak self] in
                self?.loadPopularPosts()
            })
        case .loaded:
            popularSection.addArrangedSubview(popularHeader())
            let rows = UIStackView(arrangedSubviews: popularItems.indices.map(makePopularRow))
            rows.axis = .vertical
            rows.spacing = 10
            popularSection.addArrangedSubview(rows)
        }
    }

    private func compactHeader(_ text: String) -> UILabel {
        let label = HomePreviewStateViews.label(text, size: 14, weight: .medium, color: AppStyle.muted, lineHeight: 20)
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }

    private func popularHeader() -> UIView {
        let title = HomePreviewStateViews.label(
            "커뮤니티 인기글",
            size: 18,
            weight: .medium,
            color: AppStyle.ink,
            lineHeight: 26,
            kern: -0.2
        )
        let more = UIButton(type: .system)
        more.setTitle("더보기", for: .normal)
        more.setTitleColor(brandBlue, for: .normal)
        more.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        more.accessibilityIdentifier = "home-popular-more"
        more.addTarget(self, action: #selector(openCommunity), for: .touchUpInside)
        return sectionHeader(title: title, moreButton: more)
    }

    func togglePopularLike(at index: Int) {
        guard popularItems.indices.contains(index) else { return }
        popularItems[index].toggleLike()
        renderPopular(.loaded)
        let item = popularItems[index]
        if let id = item.post?.id {
            let liked = item.liked
            CommunityPostStore.shared.syncWithServer { try await CommunityAPI.setLike(postID: id, liked: liked) }
        }
    }

    private func makePopularRow(_ index: Int) -> UIView {
        let item = popularItems[index]
        let style = HomePopularRowStyle(blue: brandBlue, softBlue: softBlue, tertiary: tertiary, border: subtleBorder)
        return HomePopularRowFactory.make(cohort: item.board, title: item.title, likes: "\(item.likes)",
            liked: item.liked, style: style, onLike: { [weak self] in
                self?.togglePopularLike(at: index)
            }, action: { [weak self] in
            guard let self else { return }
            if var post = item.post {
                post.likedByMe = item.liked
                let detail = CommunityPostDetailViewController(post: post, isMine: post.isMine)
                detail.hidesBottomBarWhenPushed = true
                self.push(detail)
            } else {
                self.openCommunity()
            }
        })
    }
}
