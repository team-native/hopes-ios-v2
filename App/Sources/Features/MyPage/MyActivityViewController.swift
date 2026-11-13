import UIKit

@MainActor
final class MyActivityViewController: AppPageViewController {
    private let segment = UISegmentedControl(items: ["작성글", "댓글"])
    private let itemsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "내 활동"
        addHeading("내 활동", subtitle: "내가 커뮤니티에 남긴 글과 댓글이에요")
        segment.selectedSegmentIndex = 0
        segment.addAction(UIAction { [weak self] _ in self?.renderItems() }, for: .valueChanged)
        contentStack.addArrangedSubview(segment)
        itemsStack.axis = .vertical
        itemsStack.spacing = 10
        contentStack.addArrangedSubview(itemsStack)
        renderItems()
    }

    private func renderItems() {
        itemsStack.arrangedSubviews.forEach { view in
            itemsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if segment.selectedSegmentIndex == 0 {
            let posts = CommunityPostStore.shared.myPosts
            guard !posts.isEmpty else {
                itemsStack.addArrangedSubview(AppStyle.label("작성한 글이 없어요", size: 14, color: AppStyle.muted))
                return
            }
            posts.forEach { post in
                addActivityRow(post.title, subtitle: "\(post.category) · \(post.time) · 댓글 \(post.comments)", symbol: "doc.text") { [weak self] in
                    self?.push(CommunityPostDetailViewController(post: post))
                }
            }
        } else {
            let comments = CommunityPostStore.shared.myComments
            guard !comments.isEmpty else {
                itemsStack.addArrangedSubview(AppStyle.label("작성한 댓글이 없어요", size: 14, color: AppStyle.muted))
                return
            }
            comments.forEach { comment in
                addActivityRow(comment.text, subtitle: "\(comment.postTitle) · \(comment.time)", symbol: "text.bubble") { [weak self] in
                    guard let post = CommunityPostStore.shared.posts.first(where: { $0.title == comment.postTitle }) else {
                        self?.showMessage("원 게시글을 찾을 수 없어요")
                        return
                    }
                    self?.push(CommunityPostDetailViewController(post: post))
                }
            }
        }
    }

    private func addActivityRow(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = AppStyle.line.cgColor
        var config = UIButton.Configuration.plain()
        config.title = title
        config.subtitle = subtitle
        config.image = UIImage(systemName: symbol)
        config.imagePlacement = .leading
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        config.baseForegroundColor = AppStyle.ink
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        itemsStack.addArrangedSubview(button)
    }
}
