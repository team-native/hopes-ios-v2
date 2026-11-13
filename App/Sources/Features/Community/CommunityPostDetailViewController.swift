import UIKit

@MainActor
final class CommunityPostDetailViewController: AppPageViewController {
    private var post: CommunityPost
    private let isMine: Bool
    private var likes: Int
    private var liked = false
    private let commentStack = UIStackView()
    private let commentField = UITextField()
    private let likeButton = UIButton(type: .system)
    private let commentEditState = UIStackView()
    private let commentEditLabel = AppStyle.label("댓글 수정 중", size: 12, color: AppStyle.blue)
    private var editingComment: String?
    private weak var editingCommentLabel: UILabel?
    private var categoryLabel: UILabel?
    private var titleLabel: UILabel?
    private var bodyLabel: UILabel?

    init(post: CommunityPost, isMine: Bool = false) {
        self.post = post
        self.isMine = isMine
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
        let postTitle = AppStyle.label(post.title, size: 21, weight: .bold)
        let body = AppStyle.label(post.body, size: 16)
        categoryLabel = category
        titleLabel = postTitle
        bodyLabel = body
        let cardStack = UIStackView(arrangedSubviews: [author, category, postTitle, body])
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
            ("9기", "기숙사 와이파이는 층마다 차이가 있더라"),
            ("나", CommunityPostStore.shared.myComments.first(where: { $0.postTitle == post.title })?.text ?? "오 고마워, 내일 아침에 말씀드려 볼게.")
        ].forEach { addComment(author: $0.0, text: $0.1) }

        configureCommentEditState()
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
        let composerGroup = UIStackView(arrangedSubviews: [commentEditState, composer])
        composerGroup.axis = .vertical
        composerGroup.spacing = 8
        contentStack.addArrangedSubview(composerGroup)
    }

    private func addComment(author: String, text: String) {
        let isOwnComment = author == "나"
        let authorLabel = AppStyle.label(isOwnComment ? "10기 (나) · 방금" : "\(author) · 익명", size: 12, weight: .medium, color: AppStyle.muted)
        let textLabel = AppStyle.label(text, size: 14)
        if isOwnComment { editingCommentLabel = textLabel }
        let header = UIStackView(arrangedSubviews: [authorLabel, UIView()])
        if isOwnComment {
            let more = UIButton(type: .system)
            more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
            more.tintColor = AppStyle.muted
            more.widthAnchor.constraint(equalToConstant: 28).isActive = true
            more.heightAnchor.constraint(equalToConstant: 24).isActive = true
            more.addAction(UIAction { [weak self, weak textLabel] _ in
                guard let self, let textLabel else { return }
                self.showOwnCommentActions(text: textLabel.text ?? "", label: textLabel)
            }, for: .touchUpInside)
            header.addArrangedSubview(more)
        }
        let stack = UIStackView(arrangedSubviews: [header, textLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.backgroundColor = .white
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14)
        stack.layer.cornerRadius = 14
        commentStack.addArrangedSubview(stack)
    }

    private func configureCommentEditState() {
        commentEditState.axis = .horizontal
        commentEditState.alignment = .center
        commentEditState.spacing = 8
        let pen = UIImageView(image: UIImage(systemName: "pencil"))
        pen.tintColor = AppStyle.blue
        pen.widthAnchor.constraint(equalToConstant: 14).isActive = true
        pen.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let cancel = UIButton(type: .system)
        cancel.setTitle("취소", for: .normal)
        cancel.setTitleColor(AppStyle.muted, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 12)
        cancel.addAction(UIAction { [weak self] _ in self?.cancelCommentEdit() }, for: .touchUpInside)
        commentEditState.addArrangedSubview(pen)
        commentEditState.addArrangedSubview(commentEditLabel)
        commentEditState.addArrangedSubview(UIView())
        commentEditState.addArrangedSubview(cancel)
        commentEditState.isHidden = true
    }

    private func showOwnCommentActions(text: String, label: UILabel) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "댓글 수정", style: .default) { [weak self] _ in
            self?.beginCommentEdit(text: text, label: label)
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }

    private func beginCommentEdit(text: String, label: UILabel) {
        editingComment = text
        editingCommentLabel = label
        commentField.text = text
        commentField.placeholder = "댓글 수정"
        commentEditState.isHidden = false
        commentField.becomeFirstResponder()
    }

    private func cancelCommentEdit() {
        editingComment = nil
        editingCommentLabel = nil
        commentField.text = nil
        commentField.placeholder = "댓글을 입력해보세요"
        commentEditState.isHidden = true
        view.endEditing(true)
    }

    private func toggleLike() {
        liked.toggle()
        likes += liked ? 1 : -1
        likeButton.setTitle("\(liked ? "♥" : "♡")  \(likes)", for: .normal)
        likeButton.setTitleColor(liked ? .systemRed : AppStyle.ink, for: .normal)
    }

    private func submitComment() {
        guard let text = commentField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        if let oldText = editingComment {
            editingCommentLabel?.text = text
            CommunityPostStore.shared.updateComment(postTitle: post.title, oldText: oldText, newText: text)
            cancelCommentEdit()
            return
        }
        addComment(author: "나", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        commentField.text = nil
        view.endEditing(true)
    }

    @objc private func showPostActions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if isMine {
            sheet.addAction(UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in self?.editPost() })
            sheet.addAction(UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in self?.confirmPostDeletion() })
        } else {
            sheet.addAction(UIAlertAction(title: "게시글 신고", style: .destructive) { [weak self] _ in self?.showReportReasons() })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }

    private func confirmPostDeletion() {
        let alert = UIAlertController(
            title: "게시글을 삭제할까요?",
            message: "삭제한 글과 댓글은 되돌릴 수 없어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            CommunityPostStore.shared.delete(self.post)
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        })
        present(alert, animated: true)
    }

    private func editPost() {
        let editor = CommunityPostEditViewController(post: post)
        editor.onSave = { [weak self] updated in
            guard let self else { return }
            self.post = updated
            self.categoryLabel?.text = updated.category
            self.titleLabel?.text = updated.title
            self.bodyLabel?.text = updated.body
        }
        push(editor)
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
