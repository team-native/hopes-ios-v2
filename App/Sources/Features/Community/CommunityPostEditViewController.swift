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
        title = nil
        view.backgroundColor = AppStyle.canvas
        contentStack.spacing = 12
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        configureHeader()
        configureBoardSelector()
        contentStack.addArrangedSubview(boardButton)
        configureFields()
        contentStack.addArrangedSubview(CommunityFormViews.flexibleSpacer())
        contentStack.addArrangedSubview(CommunityFormViews.privacyNotice())
        _ = CommunityFormViews.pinToBottom(contentStack, in: scrollView, safeArea: view.safeAreaLayoutGuide,
            minimumOffset: 11)
        view.accessibilityIdentifier = "community-edit-screen"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func configureFields() {
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

        bodyView.text = originalPost.detailBody ?? originalPost.body
        bodyView.font = .systemFont(ofSize: 15)
        bodyView.textColor = AppStyle.ink
        bodyView.backgroundColor = .white
        bodyView.layer.cornerRadius = 16
        bodyView.layer.borderWidth = 1
        bodyView.layer.borderColor = AppStyle.line.cgColor
        bodyView.textContainerInset = UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 12)
        bodyView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        bodyView.delegate = self
        contentStack.addArrangedSubview(bodyView)
    }

    private func configureHeader() {
        let close = UIButton(type: .custom)
        close.setImage(UIImage(named: "community-write-close-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        close.accessibilityLabel = "닫기"
        close.widthAnchor.constraint(equalToConstant: 44).isActive = true
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) },
            for: .touchUpInside)

        let heading = AppStyle.label("게시글 수정", size: 18, weight: .medium)
        let save = UIButton(type: .custom)
        save.setTitle("저장", for: .normal)
        save.setTitleColor(.white, for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        save.backgroundColor = AppStyle.blue
        save.layer.cornerRadius = 10
        save.accessibilityIdentifier = "community-edit-save"
        save.widthAnchor.constraint(equalToConstant: 54).isActive = true
        save.heightAnchor.constraint(equalToConstant: 36).isActive = true
        save.addAction(UIAction { [weak self] _ in self?.saveChanges() }, for: .touchUpInside)
        let row = UIStackView(arrangedSubviews: [close, heading, UIView(), save])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(row)
    }

    private func configureBoardSelector() {
        boardButton.backgroundColor = .white
        boardButton.layer.cornerRadius = 16
        boardButton.layer.borderWidth = 1
        boardButton.layer.borderColor = AppStyle.line.cgColor
        boardButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        let chevron = UIImageView(image: UIImage(named: "community-write-chevron-icon")?
            .withRenderingMode(.alwaysOriginal))
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let row = UIStackView(arrangedSubviews: [
            AppStyle.label("게시판", size: 14, weight: .medium, color: AppStyle.muted), UIView(), boardGradeLabel, chevron
        ])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        boardButton.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: boardButton.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: boardButton.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: boardButton.topAnchor),
            row.bottomAnchor.constraint(equalTo: boardButton.bottomAnchor)
        ])
        boardGradeLabel.text = selectedGrade
        boardButton.addAction(UIAction { [weak self] _ in self?.showBoardOptions() }, for: .touchUpInside)
    }

    private func showBoardOptions() {
        let picker = CommunityBoardPickerViewController(selectedBoard: selectedGrade)
        picker.onSelect = { [weak self] grade in
            self?.selectedGrade = grade
            self?.boardGradeLabel.text = grade
        }
        present(picker, animated: true)
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
