import UIKit

@MainActor
final class CommunityPostDetailViewController: AppPageViewController {
    private let post: CommunityPost
    private var likes: Int
    private var liked = false
    private let commentStack = UIStackView()
    private let commentField = UITextField()
    private let likeButton = UIButton(type: .system)

    init(post: CommunityPost) {
        self.post = post
        likes = post.likes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "게시글"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(showPostActions)
        )

        let postCard = AppStyle.card()
        let author = AppStyle.label("\(post.grade) · 익명 · \(post.time)", size: 13, color: AppStyle.muted)
        let category = AppStyle.label(post.category, size: 12, weight: .semibold, color: AppStyle.blue)
        let titleLabel = AppStyle.label(post.title, size: 21, weight: .bold)
        let body = AppStyle.label(post.body, size: 16)
        let cardStack = UIStackView(arrangedSubviews: [author, category, titleLabel, body])
        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        postCard.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: postCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: postCard.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: postCard.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: postCard.bottomAnchor, constant: -18)
        ])
        contentStack.addArrangedSubview(postCard)

        likeButton.setTitle("♡  \(likes)", for: .normal)
        likeButton.setTitleColor(AppStyle.ink, for: .normal)
        likeButton.backgroundColor = .white
        likeButton.layer.cornerRadius = 12
        likeButton.layer.borderWidth = 1
        likeButton.layer.borderColor = AppStyle.line.cgColor
        likeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        likeButton.addAction(UIAction { [weak self] _ in self?.toggleLike() }, for: .touchUpInside)
        contentStack.addArrangedSubview(likeButton)

        addSection("댓글 \(post.comments)")
        commentStack.axis = .vertical
        commentStack.spacing = 12
        contentStack.addArrangedSubview(commentStack)
        [
            ("10기", "나도 저녁 시간대에 좀 느려지는 것 같아"),
            ("9기", "기숙사 와이파이는 층마다 차이가 있더라")
        ].forEach { addComment(author: $0.0, text: $0.1) }

        let composer = UIStackView()
        composer.axis = .horizontal
        composer.spacing = 8
        commentField.placeholder = "댓글을 입력해보세요"
        commentField.borderStyle = .roundedRect
        commentField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("등록", for: .normal)
        sendButton.setTitleColor(AppStyle.blue, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        sendButton.addAction(UIAction { [weak self] _ in self?.submitComment() }, for: .touchUpInside)
        composer.addArrangedSubview(commentField)
        composer.addArrangedSubview(sendButton)
        contentStack.addArrangedSubview(composer)
    }

    private func addComment(author: String, text: String) {
        let authorLabel = AppStyle.label("\(author) · 익명", size: 12, weight: .medium, color: AppStyle.muted)
        let textLabel = AppStyle.label(text, size: 14)
        let stack = UIStackView(arrangedSubviews: [authorLabel, textLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.backgroundColor = .white
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14)
        stack.layer.cornerRadius = 14
        commentStack.addArrangedSubview(stack)
    }

    private func toggleLike() {
        liked.toggle()
        likes += liked ? 1 : -1
        likeButton.setTitle("\(liked ? "♥" : "♡")  \(likes)", for: .normal)
        likeButton.setTitleColor(liked ? .systemRed : AppStyle.ink, for: .normal)
    }

    private func submitComment() {
        guard let text = commentField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        addComment(author: "나", text: text)
        commentField.text = nil
        view.endEditing(true)
    }

    @objc private func showPostActions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "게시글 신고", style: .destructive) { [weak self] _ in self?.showReportReasons() })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }

    private func showReportReasons() {
        let sheet = UIAlertController(title: "신고 사유 선택", message: nil, preferredStyle: .actionSheet)
        ["부적절한 내용", "욕설 또는 혐오 표현", "광고·도배", "기타"].forEach { reason in
            sheet.addAction(UIAlertAction(title: reason, style: .default) { [weak self] _ in
                self?.showMessage("신고 내용을 접수했어요")
            })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }
}
