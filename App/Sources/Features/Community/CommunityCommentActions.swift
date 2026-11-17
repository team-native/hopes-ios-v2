import UIKit

@MainActor
extension CommunityPostDetailViewController {
    func addComment(author: String, time: String, text: String, commentID: Int64? = nil) {
        let isOwnComment = author == "나" || author.contains("(나)")
        let authorLabel = AppStyle.label(author, size: 14, weight: .medium,
            color: isOwnComment ? AppStyle.blue : AppStyle.ink)
        authorLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let timeLabel = AppStyle.label("· \(time)", size: 12,
            color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
        timeLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let textLabel = AppStyle.label(text, size: 14, weight: .medium)
        textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        if isOwnComment { editingCommentLabel = textLabel }
        let header = UIStackView(arrangedSubviews: [authorLabel, timeLabel, UIView()])
        let more = makeMoreButton(identifier: "community-comment-actions")
        more.imageView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        more.widthAnchor.constraint(equalToConstant: 24).isActive = true
        more.heightAnchor.constraint(equalToConstant: 24).isActive = true
        more.addAction(UIAction { [weak self, weak textLabel] _ in
            guard let self, let textLabel else { return }
            if isOwnComment {
                self.showOwnCommentActions(text: textLabel.text ?? "", label: textLabel)
            } else {
                self.showCommentReportActions(commentID: commentID)
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
        stack.spacing = 4
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        commentStack.addArrangedSubview(stack)
    }

    func retryFailedComment(text: String, card: UIStackView) {
        commentStack.removeArrangedSubview(card)
        card.removeFromSuperview()
        addComment(author: "10기 (나)", time: "방금", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        post = post.withCommentCount(post.comments + 1)
        visibleCommentCount += 1
        updateCommentCount()
    }

    func configureCommentEditState() {
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

    func showOwnCommentActions(text: String, label: UILabel) {
        guard presentedViewController == nil else { return }
        let primaryText = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        let danger = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        let sheet = CommunityActionSheetViewController(actions: [
            CommunityActionSheetAction(
                title: "댓글 수정",
                iconName: "CommunityActionEdit",
                titleColor: primaryText,
                accessibilityIdentifier: "community-comment-actions-edit",
                handler: { [weak self, weak label] in
                    guard let self, let label else { return }
                    self.beginCommentEdit(text: text, label: label)
                }
            ),
            CommunityActionSheetAction(
                title: "댓글 삭제",
                iconName: "CommunityActionDelete",
                titleColor: danger,
                accessibilityIdentifier: "community-comment-actions-delete",
                handler: { [weak self, weak label] in
                    guard let self, let label else { return }
                    self.confirmCommentDeletion(text: text, label: label)
                }
            )
        ],
            accessibilityIdentifier: "community-comment-actions-sheet",
            closeAccessibilityIdentifier: "community-comment-actions-close")
        present(sheet, animated: false)
    }

    func showCommentReportActions(commentID: Int64?) {
        let store = CommunityPostStore.shared
        if let commentID, store.reportedCommentIDs.contains(commentID) {
            showDuplicateReportToast()
            return
        }
        presentReportFlow { reasonCode in
            guard let commentID else { return }
            store.markCommentReported(id: commentID, reasonCode: reasonCode)
        }
    }

    func confirmCommentDeletion(text: String, label: UILabel) {
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
            self.post = self.post.withCommentCount(max(0, self.post.comments - 1))
            self.visibleCommentCount = max(0, self.visibleCommentCount - 1)
            self.updateCommentCount()
            if self.editingComment == text { self.cancelCommentEdit() }
            if self.editingCommentLabel === label { self.editingCommentLabel = nil }
        })
        present(alert, animated: true)
    }

    func beginCommentEdit(text: String, label: UILabel) {
        editingComment = text
        editingCommentLabel = label
        commentField.text = text
        commentField.placeholder = "댓글 수정"
        commentEditState.isHidden = false
        commentField.becomeFirstResponder()
    }

    func cancelCommentEdit() {
        editingComment = nil
        editingCommentLabel = nil
        commentField.text = nil
        commentField.placeholder = "댓글 달기"
        commentEditState.isHidden = true
        view.endEditing(true)
    }

    func toggleLike() {
        liked.toggle()
        likes += liked ? 1 : -1
        applyLikeAppearance()
        if let id = post.id {
            let liked = liked
            CommunityPostStore.shared.syncWithServer { try await CommunityAPI.setLike(postID: id, liked: liked) }
        }
    }

    func submitComment() {
        guard let text = commentField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else { return }
        if let oldText = editingComment {
            editingCommentLabel?.text = text
            CommunityPostStore.shared.updateComment(postTitle: post.title, oldText: oldText, newText: text)
            cancelCommentEdit()
            return
        }
        if shouldSimulateCommentFailure {
            // Explicit preview only; normal submissions use the server synchronization path below.
            shouldSimulateCommentFailure = false
            _ = addFailedComment(text: text)
            commentField.text = nil
            view.endEditing(true)
            return
        }
        addComment(author: "10기 (나)", time: "방금", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        post = post.withCommentCount(post.comments + 1)
        visibleCommentCount += 1
        updateCommentCount()
        commentField.text = nil
        view.endEditing(true)
    }

    @objc func showPostActions() {
        guard presentedViewController == nil else { return }
        let danger = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        let primaryText = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        let actions: [CommunityActionSheetAction]
        if isMine {
            actions = [
                CommunityActionSheetAction(
                    title: "수정하기",
                    iconName: "CommunityActionEdit",
                    titleColor: primaryText,
                    accessibilityIdentifier: "community-post-actions-edit",
                    handler: { [weak self] in self?.editPost() }
                ),
                CommunityActionSheetAction(
                    title: "삭제하기",
                    iconName: "CommunityActionDelete",
                    titleColor: danger,
                    accessibilityIdentifier: "community-post-actions-delete",
                    handler: { [weak self] in self?.confirmPostDeletion() }
                )
            ]
        } else {
            actions = [
                CommunityActionSheetAction(
                    title: "신고하기",
                    iconName: "CommunityActionReport",
                    titleColor: danger,
                    accessibilityIdentifier: "community-post-actions-report",
                    handler: { [weak self] in self?.showReportReasons() }
                )
            ]
        }
        let sheet = CommunityActionSheetViewController(
            actions: actions,
            accessibilityIdentifier: "community-post-actions-sheet"
        )
        present(sheet, animated: false)
    }

    func confirmPostDeletion() {
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

    func editPost() {
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

    func showReportReasons() {
        let store = CommunityPostStore.shared
        guard !store.hasReported(post) else {
            showDuplicateReportToast()
            return
        }
        presentReportFlow { [weak self] reasonCode in
            guard let self else { return }
            CommunityPostStore.shared.markReported(self.post, reasonCode: reasonCode)
        }
    }

    private func presentReportFlow(onSubmit: @escaping (String) -> Void = { _ in }) {
        guard presentedViewController == nil else { return }
        present(CommunityReportFlowViewController(onSubmit: onSubmit), animated: false)
    }

    private func showDuplicateReportToast() {
        view.subviews.first { $0.accessibilityIdentifier == "community-duplicate-report-toast" }?.removeFromSuperview()

        let checkCircle = UIView()
        checkCircle.backgroundColor = AppStyle.blue
        checkCircle.layer.cornerRadius = 11
        checkCircle.widthAnchor.constraint(equalToConstant: 22).isActive = true
        checkCircle.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let check = UIImageView(image: UIImage(named: "CommunityToastCheck")?.withRenderingMode(.alwaysOriginal))
        check.translatesAutoresizingMaskIntoConstraints = false
        checkCircle.addSubview(check)
        NSLayoutConstraint.activate([
            check.widthAnchor.constraint(equalToConstant: 14),
            check.heightAnchor.constraint(equalToConstant: 14),
            check.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor)
        ])

        let message = AppStyle.label("이미 신고한 게시글이에요", size: 14, weight: .medium, color: .white)
        let toast = UIStackView(arrangedSubviews: [checkCircle, message])
        toast.accessibilityIdentifier = "community-duplicate-report-toast"
        toast.accessibilityLabel = "이미 신고한 게시글이에요"
        toast.isAccessibilityElement = true
        toast.axis = .horizontal
        toast.alignment = .center
        toast.spacing = 10
        toast.isLayoutMarginsRelativeArrangement = true
        toast.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 18)
        toast.backgroundColor = AppStyle.ink.withAlphaComponent(0.92)
        toast.layer.cornerRadius = 25
        toast.layer.shadowColor = UIColor.black.cgColor
        toast.layer.shadowOpacity = 0.18
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 8)
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
        toast.alpha = 0
        UIView.animate(withDuration: 0.2) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak toast] in
            guard let toast else { return }
            UIView.animate(withDuration: 0.2, animations: { toast.alpha = 0 }, completion: { _ in
                toast.removeFromSuperview()
            })
        }
    }
}
