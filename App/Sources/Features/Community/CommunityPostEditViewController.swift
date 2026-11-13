import UIKit

@MainActor
final class CommunityPostEditViewController: AppPageViewController, UITextViewDelegate {
    var onSave: ((CommunityPost) -> Void)?

    private let originalPost: CommunityPost
    private let titleField = UITextField()
    private let bodyView = UITextView()
    private let boardButton = UIButton(type: .system)
    private let boardGradeLabel = AppStyle.label("", size: 15, weight: .medium)
    private var selectedGrade: String

    init(post: CommunityPost) {
        originalPost = post
        selectedGrade = post.grade == "익명" ? "10기" : post.grade
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "게시글 수정"
        configureHeader()

        configureBoardSelector()
        contentStack.addArrangedSubview(boardButton)

        titleField.text = originalPost.title
        titleField.font = .systemFont(ofSize: 15)
        titleField.textColor = AppStyle.ink
        titleField.backgroundColor = .white
        titleField.layer.cornerRadius = 16
        titleField.layer.borderWidth = 1
        titleField.layer.borderColor = AppStyle.line.cgColor
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        titleField.leftViewMode = .always
        titleField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        contentStack.addArrangedSubview(titleField)

        bodyView.text = originalPost.body
        bodyView.font = .systemFont(ofSize: 15)
        bodyView.textColor = AppStyle.ink
        bodyView.backgroundColor = .white
        bodyView.layer.cornerRadius = 16
        bodyView.layer.borderWidth = 1
        bodyView.layer.borderColor = AppStyle.line.cgColor
        bodyView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        bodyView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        bodyView.delegate = self
        contentStack.addArrangedSubview(bodyView)

        let notice = UIStackView()
        notice.axis = .horizontal
        notice.alignment = .top
        notice.spacing = 8
        notice.isLayoutMarginsRelativeArrangement = true
        notice.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        notice.backgroundColor = AppStyle.paleBlue
        notice.layer.cornerRadius = 14
        let lock = UIImageView(image: UIImage(systemName: "lock"))
        lock.tintColor = AppStyle.blue
        lock.widthAnchor.constraint(equalToConstant: 18).isActive = true
        lock.heightAnchor.constraint(equalToConstant: 18).isActive = true
        notice.addArrangedSubview(lock)
        notice.addArrangedSubview(AppStyle.label("작성자는 기수만 표시돼요. 이름·학번은 다른 사용자에게 공개되지 않아요.", size: 12,
            color: AppStyle.muted))
        contentStack.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(notice)
    }

    private func configureHeader() {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = AppStyle.ink
        close.widthAnchor.constraint(equalToConstant: 44).isActive = true
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) },
            for: .touchUpInside)

        let heading = AppStyle.label("게시글 수정", size: 18, weight: .semibold)
        let save = UIButton(type: .system)
        save.setTitle("저장", for: .normal)
        save.setTitleColor(.white, for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        save.backgroundColor = AppStyle.blue
        save.layer.cornerRadius = 10
        save.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        save.addAction(UIAction { [weak self] _ in self?.saveChanges() }, for: .touchUpInside)
        let row = UIStackView(arrangedSubviews: [close, heading, UIView(), save])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        contentStack.addArrangedSubview(row)
    }

    private func configureBoardSelector() {
        boardButton.backgroundColor = .white
        boardButton.layer.cornerRadius = 16
        boardButton.layer.borderWidth = 1
        boardButton.layer.borderColor = AppStyle.line.cgColor
        boardButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        boardButton.contentHorizontalAlignment = .fill
        let row = UIStackView(arrangedSubviews: [
            AppStyle.label("게시판", size: 14, weight: .medium, color: AppStyle.muted),
            UIView(),
            boardGradeLabel,
            UIImageView(image: UIImage(systemName: "chevron.down"))
        ])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        (row.arrangedSubviews.last as? UIImageView)?.tintColor = AppStyle.muted
        row.translatesAutoresizingMaskIntoConstraints = false
        boardButton.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: boardButton.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: boardButton.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: boardButton.topAnchor),
            row.bottomAnchor.constraint(equalTo: boardButton.bottomAnchor)
        ])
        updateBoardButton()
        boardButton.addAction(UIAction { [weak self] _ in self?.showBoardOptions() }, for: .touchUpInside)
    }

    private func updateBoardButton() {
        boardGradeLabel.text = selectedGrade
    }

    private func showBoardOptions() {
        let sheet = UIAlertController(title: "게시판 선택", message: nil, preferredStyle: .actionSheet)
        ["전체", "8기", "9기", "10기", "11기"].forEach { grade in
            sheet.addAction(UIAlertAction(title: grade, style: .default) { [weak self] _ in
                self?.selectedGrade = grade
                self?.updateBoardButton()
            })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController { popover.sourceView = boardButton
            popover.sourceRect = boardButton.bounds }
        present(sheet, animated: true)
    }

    private func saveChanges() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !body.isEmpty else {
            showMessage("제목과 내용을 입력해주세요")
            return
        }
        let updated = CommunityPostStore.shared.update(originalPost, title: title, body: body, grade: selectedGrade)
        onSave?(updated)
        navigationController?.popViewController(animated: true)
    }
}
