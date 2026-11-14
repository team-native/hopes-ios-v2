import UIKit

@MainActor
final class CommunityPostDetailViewController: AppPageViewController, UITextFieldDelegate {
    var post: CommunityPost
    let isMine: Bool
    var likes: Int
    var liked = false
    let commentStack = UIStackView()
    let commentField = UITextField()
    let likeButton = UIButton(type: .system)
    let composerBar = UIView()
    let commentCountButton = UIButton(type: .system)
    let commentEditState = UIStackView()
    let commentEditLabel = AppStyle.label("댓글 수정 중", size: 12, color: AppStyle.blue)
    var editingComment: String?
    weak var editingCommentLabel: UILabel?
    var gradeBadgeLabel: UILabel?
    var boardSubtitleLabel: UILabel?
    var titleLabel: UILabel?
    var bodyLabel: UILabel?
    var commentCountLabel: UILabel?
    var visibleCommentCount = 3
    weak var postMoreButton: UIButton?
    var shouldSimulateCommentFailure = true
    var composerBottomConstraint: NSLayoutConstraint!
    var keyboardObserver: NSObjectProtocol?

    init(post: CommunityPost, isMine: Bool = false) {
        self.post = post
        self.isMine = isMine
        likes = post.likes
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        guard isPostAvailable else {
            showDeletedPostState()
            return
        }
        if let bottomConstraint = view.constraints.first(where: {
            $0.firstItem === scrollView && $0.firstAttribute == .bottom
        }) {
            bottomConstraint.isActive = false
        }
        scrollView.contentInsetAdjustmentBehavior = .never

        addHeader()
        contentStack.addArrangedSubview(makePostCard())

        configureComments()
        configureCommentEditState()
        configureComposer()
        constrainConversationToComposer()
        observeKeyboard()
        view.accessibilityIdentifier = "community-post-detail-screen"
    }

    private func configureComments() {
        let commentCount = AppStyle.label(
            "댓글 \(visibleCommentCount)",
            size: 14,
            weight: .medium,
            color: secondaryText
        )
        commentCountLabel = commentCount
        contentStack.addArrangedSubview(commentCount)
        commentStack.axis = .vertical
        commentStack.spacing = 0
        let card = makeCommentsCard()
        contentStack.addArrangedSubview(card)
        addInitialComments()
    }

    private func makeCommentsCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255,
            alpha: 1).withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.addSubview(commentStack)
        commentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            commentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 4),
            commentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            commentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            commentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4)
        ])
        return card
    }

    private func addInitialComments() {
        let myComment = CommunityPostStore.shared.myComments.first { $0.postTitle == post.title }?.text
        let comments = [
            ("10기", "5분 전", "2층도 저녁엔 느려. 공유기 위치 문제 같아."),
            ("9기", "3분 전", "사감 선생님께 말씀드리면 점검해 주신대!"),
            ("10기 (나)", "방금", myComment ?? "오 고마워, 내일 말씀드려 볼게.")
        ]
        comments.forEach { addComment(author: $0.0, time: $0.1, text: $0.2) }
    }

    private func constrainConversationToComposer() {
        scrollView.bottomAnchor.constraint(equalTo: composerBar.topAnchor, constant: -16).isActive = true
    }

    let secondaryText = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    deinit {
        if let keyboardObserver { NotificationCenter.default.removeObserver(keyboardObserver) }
    }

}

@MainActor
extension CommunityPostDetailViewController {
    func configureComposer() {
        composerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composerBar)
        let row = UIStackView(arrangedSubviews: [commentField, makeSendButton()])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        let stack = UIStackView(arrangedSubviews: [commentEditState, row])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        composerBar.addSubview(stack)

        commentField.placeholder = "댓글 달기"
        commentField.font = .systemFont(ofSize: 14)
        commentField.textColor = AppStyle.ink
        commentField.backgroundColor = .white
        commentField.layer.cornerRadius = 25
        commentField.layer.borderWidth = 1
        commentField.layer.borderColor = AppStyle.line.cgColor
        commentField.returnKeyType = .send
        commentField.delegate = self
        commentField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        commentField.leftViewMode = .always
        commentField.heightAnchor.constraint(equalToConstant: 52).isActive = true

        NSLayoutConstraint.activate([
            composerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            composerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: composerBar.topAnchor),
            stack.leadingAnchor.constraint(equalTo: composerBar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: composerBar.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: composerBar.bottomAnchor)
        ])
        composerBottomConstraint = composerBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )
        composerBottomConstraint.isActive = true
        scrollView.keyboardDismissMode = .interactive
    }

    func observeKeyboard() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                let userInfo = notification.userInfo ?? [:]
                let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey]
                let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey]
                guard let self,
                      let frame = frameValue as? CGRect,
                      let duration = durationValue as? TimeInterval else { return }
                let local = self.view.convert(frame, from: nil)
                let overlap = max(0, self.view.safeAreaLayoutGuide.layoutFrame.maxY - local.minY)
                self.composerBottomConstraint.constant = -8 - overlap
                UIView.animate(withDuration: duration) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

}

@MainActor
extension CommunityPostDetailViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitComment()
        return true
    }

    func makeSendButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "community-detail-send-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = AppStyle.blue
        button.layer.cornerRadius = 24
        button.accessibilityLabel = "댓글 등록"
        button.accessibilityIdentifier = "community-comment-send"
        button.addAction(UIAction { [weak self] _ in self?.submitComment() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 48),
            button.heightAnchor.constraint(equalToConstant: 48)
        ])
        return button
    }

    var isPostAvailable: Bool {
        let posts = isMine ? CommunityPostStore.shared.myPosts : CommunityPostStore.shared.posts
        return posts.contains { $0.title == post.title && $0.body == post.body }
    }

}
