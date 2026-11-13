import UIKit

@MainActor
final class CommunityWriteViewController: AppPageViewController, UITextViewDelegate {
    private let titleField = UITextField()
    private let bodyView = UITextView()
    private let bodyPlaceholder = "내용을 입력하세요"
    private var selectedBoard = "10기"
    private let boardValue = AppStyle.label("10기", size: 15, weight: .medium)
    private let titleErrorLabel = AppStyle.label("", size: 12, color: .systemRed)
    private let bodyErrorLabel = AppStyle.label("", size: 12, color: .systemRed)
    private var titleErrorRow: UIStackView?
    private var bodyErrorRow: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "글쓰기"
        contentStack.spacing = 12

        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(cancel))
        closeButton.tintColor = AppStyle.ink
        navigationItem.leftBarButtonItem = closeButton

        let registerButton = UIButton(type: .system)
        var registerConfiguration = UIButton.Configuration.filled()
        registerConfiguration.title = "등록"
        registerConfiguration.baseBackgroundColor = AppStyle.blue
        registerConfiguration.baseForegroundColor = .white
        registerConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        registerButton.configuration = registerConfiguration
        registerButton.layer.cornerRadius = 10
        registerButton.clipsToBounds = true
        registerButton.addAction(UIAction { [weak self] _ in self?.publish() }, for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: registerButton)

        contentStack.addArrangedSubview(makeBoardRow())
        configureTitleField()
        let titleGroup = UIStackView(arrangedSubviews: [titleField, makeErrorRow(titleErrorLabel)])
        titleGroup.axis = .vertical
        titleGroup.spacing = 6
        contentStack.addArrangedSubview(titleGroup)
        configureBodyView()
        let bodyGroup = UIStackView(arrangedSubviews: [bodyView, makeErrorRow(bodyErrorLabel)])
        bodyGroup.axis = .vertical
        bodyGroup.spacing = 6
        contentStack.addArrangedSubview(bodyGroup)
        contentStack.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(makePrivacyNotice())
    }

    private func makeBoardRow() -> UIButton {
        let label = AppStyle.label("게시판", size: 14, weight: .medium, color: AppStyle.muted)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = AppStyle.muted
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 16).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let row = UIStackView(arrangedSubviews: [label, UIView(), boardValue, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        let button = UIButton(type: .custom)
        button.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 54)
        ])
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = AppStyle.line.cgColor
        button.addAction(UIAction { [weak self] _ in self?.presentBoardPicker() }, for: .touchUpInside)
        return button
    }

    private func presentBoardPicker() {
        view.endEditing(true)
        let picker = CommunityBoardPickerViewController(selectedBoard: selectedBoard)
        picker.onSelect = { [weak self] board in
            self?.selectedBoard = board
            self?.boardValue.text = board
        }
        present(picker, animated: true)
    }

    private func configureTitleField() {
        titleField.placeholder = "제목"
        titleField.font = .systemFont(ofSize: 15)
        titleField.textColor = AppStyle.ink
        titleField.backgroundColor = .white
        titleField.layer.cornerRadius = 16
        titleField.layer.borderWidth = 1
        titleField.layer.borderColor = AppStyle.line.cgColor
        titleField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        titleField.leftView = padding
        titleField.leftViewMode = .always
        titleField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
    }

    private func makeErrorRow(_ label: UILabel) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = .systemRed
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        row.isHidden = true
        if label === titleErrorLabel {
            titleErrorRow = row
        } else {
            bodyErrorRow = row
        }
        return row
    }

    private func configureBodyView() {
        bodyView.font = .systemFont(ofSize: 15)
        bodyView.textColor = AppStyle.muted
        bodyView.text = bodyPlaceholder
        bodyView.backgroundColor = .white
        bodyView.layer.cornerRadius = 16
        bodyView.layer.borderWidth = 1
        bodyView.layer.borderColor = AppStyle.line.cgColor
        bodyView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        bodyView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        bodyView.delegate = self
    }

    private func makePrivacyNotice() -> UIView {
        let lock = UIImageView(image: UIImage(systemName: "lock.fill"))
        lock.tintColor = AppStyle.blue
        lock.widthAnchor.constraint(equalToConstant: 18).isActive = true
        lock.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("작성자는 기수만 표시돼요. 이름·학번은 다른 사용자에게 공개되지 않아요.", size: 12, color: AppStyle.muted)
        let notice = UIStackView(arrangedSubviews: [lock, message])
        notice.axis = .horizontal
        notice.alignment = .top
        notice.spacing = 8
        notice.isLayoutMarginsRelativeArrangement = true
        notice.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        notice.backgroundColor = AppStyle.paleBlue
        notice.layer.cornerRadius = 16
        return notice
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == bodyPlaceholder {
            textView.text = ""
            textView.textColor = AppStyle.ink
        }
        if bodyErrorRow?.isHidden != false {
            bodyView.layer.borderColor = AppStyle.blue.withAlphaComponent(0.55).cgColor
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = bodyPlaceholder
            textView.textColor = AppStyle.muted
        }
        bodyView.layer.borderColor = bodyErrorRow?.isHidden == false ? UIColor.systemRed.cgColor : AppStyle.line.cgColor
    }

    func textViewDidChange(_ textView: UITextView) {
        guard !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        setBodyError(false)
    }

    @objc private func titleDidChange() {
        guard !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        setTitleError(false)
    }

    @objc private func cancel() {
        let hasDraft = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (!bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && bodyView.text != bodyPlaceholder)
        guard hasDraft else {
            navigationController?.popViewController(animated: true)
            return
        }

        let alert = UIAlertController(
            title: "작성을 그만둘까요?",
            message: "지금 나가면 작성 중인 글이 사라져요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "계속 쓰기", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func publish() {
        view.endEditing(true)
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text == bodyPlaceholder ? "" : bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        setTitleError(titleText.isEmpty)
        setBodyError(bodyText.isEmpty)
        guard !titleText.isEmpty, !bodyText.isEmpty else {
            return
        }
        CommunityPostStore.shared.add(title: titleText, body: bodyText, category: "질문", grade: selectedBoard)
        navigationController?.popViewController(animated: true)
    }

    private func setTitleError(_ isError: Bool) {
        titleErrorLabel.text = isError ? "제목을 입력해 주세요." : nil
        titleErrorRow?.isHidden = !isError
        titleField.layer.borderWidth = isError ? 1.5 : 1
        titleField.layer.borderColor = isError ? UIColor.systemRed.cgColor : AppStyle.line.cgColor
    }

    private func setBodyError(_ isError: Bool) {
        bodyErrorLabel.text = isError ? "내용을 입력해 주세요." : nil
        bodyErrorRow?.isHidden = !isError
        bodyView.layer.borderWidth = isError ? 1.5 : 1
        bodyView.layer.borderColor = isError ? UIColor.systemRed.cgColor : AppStyle.line.cgColor
    }
}
