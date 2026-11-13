import UIKit

@MainActor
extension CommunityPostDetailViewController {
    func addComment(author: String, time: String, text: String) {
        let isOwnComment = author == "나" || author.contains("(나)")
        let authorLabel = AppStyle.label("\(author) · \(time)", size: 12, weight: .medium,
            color: isOwnComment ? AppStyle.blue : AppStyle.muted)
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

    func addFailedComment(text: String) -> UIStackView {
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

    func retryFailedComment(text: String, card: UIStackView) {
        commentStack.removeArrangedSubview(card)
        card.removeFromSuperview()
        addComment(author: "10기 (나)", time: "방금", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        post = CommunityPost(grade: post.grade, title: post.title, body: post.body, time: post.time,
            comments: post.comments + 1, likes: post.likes, category: post.category, detailBody: post.detailBody)
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

    func showOwnCommentActions(text: String, label: UILabel, source: UIButton) {
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

    func showCommentReportActions(source: UIButton) {
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
            self.post = CommunityPost(grade: self.post.grade, title: self.post.title, body: self.post.body,
                time: self.post.time, comments: max(0, self.post.comments - 1), likes: self.post.likes,
                    category: self.post.category, detailBody: self.post.detailBody)
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
        let color = liked ? AppStyle.blue : UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        let image = UIImage(systemName: liked ? "heart.fill" : "heart")?.withTintColor(color,
            renderingMode: .alwaysOriginal)
        likeButton.setImage(image, for: .normal)
        likeButton.setTitle("\(likes)", for: .normal)
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
            // The prototype has no comment API yet; this reproduces a transient send failure once per detail session.
            shouldSimulateCommentFailure = false
            _ = addFailedComment(text: text)
            commentField.text = nil
            view.endEditing(true)
            return
        }
        addComment(author: "10기 (나)", time: "방금", text: text)
        CommunityPostStore.shared.addComment(postTitle: post.title, text: text)
        post = CommunityPost(grade: post.grade, title: post.title, body: post.body, time: post.time,
            comments: post.comments + 1, likes: post.likes, category: post.category, detailBody: post.detailBody)
        visibleCommentCount += 1
        updateCommentCount()
        commentField.text = nil
        view.endEditing(true)
    }

    @objc func showPostActions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if isMine {
            sheet.addAction(UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in self?.editPost() })
            sheet.addAction(UIAlertAction(title: "삭제하기",
                style: .destructive) { [weak self] _ in self?.confirmPostDeletion() })
        } else {
            sheet.addAction(UIAlertAction(title: "게시글 신고",
                style: .destructive) { [weak self] _ in self?.showReportReasons() })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = postMoreButton
            popover.sourceRect = postMoreButton?.bounds ?? .zero
        }
        present(sheet, animated: true)
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
    }}
