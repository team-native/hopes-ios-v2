import UIKit

@MainActor
final class CommunityPostDetailViewController: AppPageViewController, UITextFieldDelegate {
    private var post: CommunityPost
    private let isMine: Bool
    private var likes: Int
    private var liked = false
    private let commentStack = UIStackView()
    private let commentField = UITextField()
    private let likeButton = UIButton(type: .system)
    private let composerBar = UIView()
    private let commentCountButton = UIButton(type: .system)
    private let commentEditState = UIStackView()
    private let commentEditLabel = AppStyle.label("댓글 수정 중", size: 12, color: AppStyle.blue)
    private var editingComment: String?
    private weak var editingCommentLabel: UILabel?
    private var gradeBadgeLabel: UILabel?
    private var boardSubtitleLabel: UILabel?
    private var titleLabel: UILabel?
    private var bodyLabel: UILabel?
    private var commentCountLabel: UILabel?
    private var visibleCommentCount = 3
    private weak var postMoreButton: UIButton?
    private var shouldSimulateCommentFailure = true
    private var composerBottomConstraint: NSLayoutConstraint!
    private var keyboardObserver: NSObjectProtocol?

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

        let commentCount = AppStyle.label("댓글 \(visibleCommentCount)", size: 14, weight: .medium, color: secondaryText)
        commentCountLabel = commentCount
        contentStack.addArrangedSubview(commentCount)
        commentStack.axis = .vertical
        commentStack.spacing = 0
        let commentsCard = UIView()
        commentsCard.backgroundColor = .white
        commentsCard.layer.cornerRadius = 24
        commentsCard.layer.borderWidth = 1
        commentsCard.layer.borderColor = AppStyle.line.cgColor
        commentsCard.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).withAlphaComponent(0.05).cgColor
        commentsCard.layer.shadowOpacity = 1
        commentsCard.layer.shadowRadius = 8
        commentsCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        commentsCard.addSubview(commentStack)
        commentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            commentStack.topAnchor.constraint(equalTo: commentsCard.topAnchor, constant: 4),
            commentStack.leadingAnchor.constraint(equalTo: commentsCard.leadingAnchor, constant: 16),
            commentStack.trailingAnchor.constraint(equalTo: commentsCard.trailingAnchor, constant: -16),
            commentStack.bottomAnchor.constraint(equalTo: commentsCard.bottomAnchor, constant: -4)
        ])
        contentStack.addArrangedSubview(commentsCard)
        [
            ("10기", "5분 전", "2층도 저녁엔 느려. 공유기 위치 문제 같아."),
            ("9기", "3분 전", "사감 선생님께 말씀드리면 점검해 주신대!"),
            ("10기 (나)", "방금", CommunityPostStore.shared.myComments.first(where: { $0.postTitle == post.title })?.text ?? "오 고마워, 내일 말씀드려 볼게.")
        ].forEach { addComment(author: $0.0, time: $0.1, text: $0.2) }

        configureCommentEditState()
        configureComposer()
        scrollView.bottomAnchor.constraint(equalTo: composerBar.topAnchor, constant: -16).isActive = true
        observeKeyboard()
        view.accessibilityIdentifier = "community-post-detail-screen"
    }

    private let secondaryText = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)

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

    private func addHeader() {
        let back = UIButton(type: .system)
        back.translatesAutoresizingMaskIntoConstraints = false
        back.setImage(UIImage(named: "community-detail-back-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        back.accessibilityLabel = "뒤로"
        back.accessibilityIdentifier = "community-post-back"
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            back.widthAnchor.constraint(equalToConstant: 44),
            back.heightAnchor.constraint(equalToConstant: 44)
        ])

        let title = AppStyle.label("게시글", size: 18, weight: .medium, color: AppStyle.ink)
        let subtitle = AppStyle.label("\(post.grade) 게시판", size: 12, color: secondaryText)
        boardSubtitleLabel = subtitle
        title.heightAnchor.constraint(equalToConstant: 26).isActive = true
        subtitle.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 0
        let header = UIStackView(arrangedSubviews: [back, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func makePostCard() -> UIView {
        let badge = makeGradeBadge(post.grade)
        gradeBadgeLabel = badge.arrangedSubviews.first as? UILabel
        let more = makeMoreButton(identifier: "community-post-actions")
        postMoreButton = more
        more.addAction(UIAction { [weak self] _ in self?.showPostActions() }, for: .touchUpInside)

        let head = UIStackView(arrangedSubviews: [badge, UIView(), more])
        head.axis = .horizontal
        head.alignment = .center

        let title = AppStyle.label(post.title, size: 16, weight: .medium)
        titleLabel = title
        let meta = AppStyle.label("\(post.grade) · \(post.time)", size: 12, color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
        let body = AppStyle.label(post.detailBody ?? post.body, size: 15, color: AppStyle.ink)
        body.textColor = AppStyle.ink
        bodyLabel = body

        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.setImage(UIImage(named: "community-detail-heart-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        likeButton.setTitle("\(likes)", for: .normal)
        likeButton.setTitleColor(AppStyle.blue, for: .normal)
        likeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        likeButton.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        likeButton.layer.cornerRadius = 17
        likeButton.accessibilityIdentifier = "community-post-like"
        likeButton.addAction(UIAction { [weak self] _ in self?.toggleLike() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            likeButton.heightAnchor.constraint(equalToConstant: 34),
            likeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])

        let comments = commentCountButton
        comments.translatesAutoresizingMaskIntoConstraints = false
        configureCommentCountButton()
        let actions = UIStackView(arrangedSubviews: [likeButton, comments, UIView()])
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 8

        let content = UIStackView(arrangedSubviews: [head, title, meta, body, actions])
        content.axis = .vertical
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func makeGradeBadge(_ grade: String) -> UIStackView {
        let label = AppStyle.label(grade, size: 12, color: AppStyle.blue)
        label.textAlignment = .center
        let badge = UIStackView(arrangedSubviews: [label])
        badge.axis = .horizontal
        badge.alignment = .center
        badge.isLayoutMarginsRelativeArrangement = true
        badge.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        badge.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        badge.layer.cornerRadius = 12
        return badge
    }

    private func configureCommentCountButton() {
        commentCountButton.translatesAutoresizingMaskIntoConstraints = false
        commentCountButton.setImage(UIImage(named: "community-detail-comment-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        commentCountButton.setTitle("\(visibleCommentCount)", for: .normal)
        commentCountButton.setTitleColor(secondaryText, for: .normal)
        commentCountButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        commentCountButton.backgroundColor = .white
        commentCountButton.layer.cornerRadius = 17
        commentCountButton.layer.borderWidth = 1
        commentCountButton.layer.borderColor = AppStyle.line.cgColor
        commentCountButton.accessibilityIdentifier = "community-post-comment-count"
        commentCountButton.addAction(UIAction { [weak self] _ in self?.commentField.becomeFirstResponder() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            commentCountButton.heightAnchor.constraint(equalToConstant: 34),
            commentCountButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])
    }

    private func updateCommentCount() {
        commentCountLabel?.text = "댓글 \(visibleCommentCount)"
        commentCountButton.setTitle("\(visibleCommentCount)", for: .normal)
    }

    private func makeMoreButton(identifier: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "community-detail-more-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = "더 보기"
        button.accessibilityIdentifier = identifier
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        return button
    }

    private func configureComposer() {
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
        composerBottomConstraint = composerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        composerBottomConstraint.isActive = true
        scrollView.keyboardDismissMode = .interactive
    }

    private func observeKeyboard() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self,
                      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
                let local = self.view.convert(frame, from: nil)
                let overlap = max(0, self.view.safeAreaLayoutGuide.layoutFrame.maxY - local.minY)
                self.composerBottomConstraint.constant = -8 - overlap
                UIView.animate(withDuration: duration) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitComment()
        return true
    }

    private func makeSendButton() -> UIButton {
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

    private var isPostAvailable: Bool {
        let posts = isMine ? CommunityPostStore.shared.myPosts : CommunityPostStore.shared.posts
        return posts.contains { $0.title == post.title && $0.body == post.body }
    }

    private func showDeletedPostState() {
        let circle = UIView()
        circle.backgroundColor = .white
        circle.layer.cornerRadius = 44
        circle.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        circle.layer.shadowOpacity = 0.10
        circle.layer.shadowRadius = 14
        circle.layer.shadowOffset = CGSize(width: 0, height: 6)
        circle.widthAnchor.constraint(equalToConstant: 88).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let trash = UIImageView(image: UIImage(systemName: "trash"))
        trash.tintColor = AppStyle.blue
        trash.contentMode = .scaleAspectFit
        circle.addSubview(trash)
        trash.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trash.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            trash.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            trash.widthAnchor.constraint(equalToConstant: 36),
            trash.heightAnchor.constraint(equalToConstant: 36)
        ])

        let heading = AppStyle.label("삭제된 게시글이에요", size: 18, weight: .semibold)
        heading.textAlignment = .center
        let message = AppStyle.label("작성자가 삭제했거나 운영 정책에 따라 숨겨진 글이에요.", size: 14, color: AppStyle.muted)
        message.textAlignment = .center

        let listButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "목록으로"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        listButton.configuration = configuration
        listButton.layer.cornerRadius = 10
        listButton.clipsToBounds = true
        listButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        listButton.addAction(UIAction { [weak self] _ in self?.returnToCommunityList() }, for: .touchUpInside)

        let state = UIStackView(arrangedSubviews: [circle, heading, message, listButton])
        state.axis = .vertical
        state.alignment = .center
        state.spacing = 12

        let container = UIView()
        container.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor, constant: -40).isActive = true
        container.addSubview(state)
        state.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            state.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            state.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            message.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 12),
            message.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(container)
    }

    private func returnToCommunityList() {
        if let tabBarController,
           let viewControllers = tabBarController.viewControllers,
           viewControllers.indices.contains(2),
           let communityNavigation = viewControllers[2] as? UINavigationController {
            tabBarController.selectedViewController = communityNavigation
            communityNavigation.popToRootViewController(animated: true)
        } else if let navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func addComment(author: String, time: String, text: String) {
        let isOwnComment = author == "나" || author.contains("(나)")
        let authorLabel = AppStyle.label("\(author) · \(time)", size: 12, weight: .medium, color: isOwnComment ? AppStyle.blue : AppStyle.muted)
        let textLabel = AppStyle.label(text, size: 14)
        if isOwnComment { editingCommentLabel = textLabel }
        let header = UIStackView(arrangedSubviews: [authorLabel, UIView()])
        let more = makeMoreButton(identifier: "community-comment-actions")
        more.widthAnchor.constraint(equalToConstant: 24).isActive = true
        more.heightAnchor.constraint(equalToConstant: 24).isActive = true
        more.addAction(UIAction { [weak self, weak textLabel, weak more] _ in
            guard let self, let textLabel, let more else { return }
            if isOwnComment {
                self.showOwnCommentActions(text: textLabel.text ?? "", label: textLabel, source: more)
            } else {
                self.showCommentReportActions(source: more)
            }
        }, for: .touchUpInside)
        header.addArrangedSubview(more)

        let stack = UIStackView()
        if !commentStack.arrangedSubviews.isEmpty {
            let divider = UIView()
            divider.backgroundColor = AppStyle.line
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            stack.addArrangedSubview(divider)
        }
        stack.addArrangedSubview(header)
        stack.addArrangedSubview(textLabel)
        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        commentStack.addArrangedSubview(stack)
    }

    private func addFailedComment(text: String) -> UIStackView {
        let author = AppStyle.label("10기 (나)", size: 12, weight: .medium, color: AppStyle.blue)
        let status = AppStyle.label("· 전송 실패", size: 12, color: AppStyle.muted)
        let retry = UIButton(type: .system)
        retry.setTitle("· 다시 시도", for: .normal)
        retry.setTitleColor(AppStyle.muted, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 12)
        let more = AppStyle.label("···", size: 14, color: AppStyle.muted)
        let header = UIStackView(arrangedSubviews: [author, status, retry, UIView(), more])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 4

        let textLabel = AppStyle.label(text, size: 14, color: UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1))
        let card = UIStackView(arrangedSubviews: [header, textLabel])
        card.axis = .vertical
        card.spacing = 6
        card.backgroundColor = .white
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14)
        commentStack.addArrangedSubview(card)
        retry.addAction(UIAction { [weak self, weak card] _ in
            guard let self, let card else { return }
            self.retryFailedComment(text: text, card: card)
        }, for: .touchUpInside)
        return card
    }

    private func retryFailedComment(text: String, card: UIStackView) {
        commentStack.removeArrangedSubview(card)
        card.removeFromSuperview()
        addComment(author: "10기 (나)", time: "방금", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        post = CommunityPost(grade: post.grade, title: post.title, body: post.body, time: post.time, comments: post.comments + 1, likes: post.likes, category: post.category, detailBody: post.detailBody)
        visibleCommentCount += 1
        updateCommentCount()
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

    private func showOwnCommentActions(text: String, label: UILabel, source: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "댓글 수정", style: .default) { [weak self] _ in
            self?.beginCommentEdit(text: text, label: label)
        })
        sheet.addAction(UIAlertAction(title: "댓글 삭제", style: .destructive) { [weak self, weak label] _ in
            guard let self, let label else { return }
            self.confirmCommentDeletion(text: text, label: label)
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = source
            popover.sourceRect = source.bounds
        }
        present(sheet, animated: true)
    }

    private func showCommentReportActions(source: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "댓글 신고", style: .destructive) { [weak self] _ in
            self?.showMessage("신고 내용을 접수했어요")
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = source
            popover.sourceRect = source.bounds
        }
        present(sheet, animated: true)
    }

    private func confirmCommentDeletion(text: String, label: UILabel) {
        let alert = UIAlertController(
            title: "댓글을 삭제할까요?",
            message: "삭제한 댓글은 되돌릴 수 없어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self, weak label] _ in
            guard let self, let label else { return }
            CommunityPostStore.shared.deleteComment(postTitle: self.post.title, text: text)
            if let commentCard = label.superview, self.commentStack.arrangedSubviews.contains(commentCard) {
                self.commentStack.removeArrangedSubview(commentCard)
                commentCard.removeFromSuperview()
            }
            self.post = CommunityPost(grade: self.post.grade, title: self.post.title, body: self.post.body, time: self.post.time, comments: max(0, self.post.comments - 1), likes: self.post.likes, category: self.post.category, detailBody: self.post.detailBody)
            self.visibleCommentCount = max(0, self.visibleCommentCount - 1)
            self.updateCommentCount()
            if self.editingComment == text { self.cancelCommentEdit() }
            if self.editingCommentLabel === label { self.editingCommentLabel = nil }
        })
        present(alert, animated: true)
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
        commentField.placeholder = "댓글 달기"
        commentEditState.isHidden = true
        view.endEditing(true)
    }

    private func toggleLike() {
        liked.toggle()
        likes += liked ? 1 : -1
        let color = liked ? AppStyle.blue : UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        let image = UIImage(systemName: liked ? "heart.fill" : "heart")?.withTintColor(color, renderingMode: .alwaysOriginal)
        likeButton.setImage(image, for: .normal)
        likeButton.setTitle("\(likes)", for: .normal)
    }

    private func submitComment() {
        guard let text = commentField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        if let oldText = editingComment {
            editingCommentLabel?.text = text
            CommunityPostStore.shared.updateComment(postTitle: post.title, oldText: oldText, newText: text)
            cancelCommentEdit()
            return
        }
        if shouldSimulateCommentFailure {
            // The prototype has no comment API yet; this reproduces a transient send failure once per detail session.
            shouldSimulateCommentFailure = false
            _ = addFailedComment(text: text)
            commentField.text = nil
            view.endEditing(true)
            return
        }
        addComment(author: "10기 (나)", time: "방금", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        post = CommunityPost(grade: post.grade, title: post.title, body: post.body, time: post.time, comments: post.comments + 1, likes: post.likes, category: post.category, detailBody: post.detailBody)
        visibleCommentCount += 1
        updateCommentCount()
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
            popover.sourceView = postMoreButton
            popover.sourceRect = postMoreButton?.bounds ?? .zero
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
            self.gradeBadgeLabel?.text = updated.grade
            self.boardSubtitleLabel?.text = "\(updated.grade) 게시판"
            self.titleLabel?.text = updated.title
            self.bodyLabel?.text = updated.detailBody ?? updated.body
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
            popover.sourceView = postMoreButton
            popover.sourceRect = postMoreButton?.bounds ?? .zero
        }
        present(sheet, animated: true)
    }
}
