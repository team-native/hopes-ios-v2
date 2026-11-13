import UIKit

@MainActor
final class CommunityWriteViewController: AppPageViewController, UITextViewDelegate {
    private let titleField = UITextField()
    private let bodyView = UITextView()
    private let bodyPlaceholder = "내용을 입력하세요"
    private let selectedBoard = "10기"

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
        contentStack.addArrangedSubview(titleField)
        configureBodyView()
        contentStack.addArrangedSubview(bodyView)
        contentStack.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(makePrivacyNotice())
    }

    private func makeBoardRow() -> UIView {
        let label = AppStyle.label("게시판", size: 14, weight: .medium, color: AppStyle.muted)
        let value = AppStyle.label(selectedBoard, size: 15, weight: .medium)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = AppStyle.muted
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 16).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let row = UIStackView(arrangedSubviews: [label, UIView(), value, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        row.backgroundColor = .white
        row.layer.cornerRadius = 16
        row.layer.borderWidth = 1
        row.layer.borderColor = AppStyle.line.cgColor
        return row
    }

    private func configureTitleField() {
        titleField.placeholder = "제목을 입력하세요"
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
        bodyView.layer.borderColor = AppStyle.blue.withAlphaComponent(0.55).cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = bodyPlaceholder
            textView.textColor = AppStyle.muted
        }
        bodyView.layer.borderColor = AppStyle.line.cgColor
    }

    @objc private func cancel() { navigationController?.popViewController(animated: true) }

    private func publish() {
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text == bodyPlaceholder ? "" : bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleText.isEmpty, !bodyText.isEmpty else {
            showMessage("제목과 내용을 입력해주세요")
            return
        }
        CommunityPostStore.shared.add(title: titleText, body: bodyText, category: "질문", anonymous: false)
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
}
