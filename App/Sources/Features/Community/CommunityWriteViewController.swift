import UIKit

@MainActor
final class CommunityWriteViewController: AppPageViewController, UITextViewDelegate {
    private let titleField = UITextField()
    private let bodyView = UITextView()
    private let categoryControl = UISegmentedControl(items: ["질문", "정보"])
    private let anonymousSwitch = UISwitch()
    private let bodyPlaceholder = "학교생활 이야기를 자유롭게 적어주세요"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "글 작성"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "등록", style: .done, target: self, action: #selector(publish))

        addHeading("새 글 작성", subtitle: "궁금한 점이나 도움이 되는 정보를 나눠보세요")
        contentStack.addArrangedSubview(AppStyle.label("카테고리", size: 15, weight: .semibold))
        categoryControl.selectedSegmentIndex = 0
        contentStack.addArrangedSubview(categoryControl)

        contentStack.addArrangedSubview(AppStyle.label("제목", size: 15, weight: .semibold))
        titleField.placeholder = "제목을 입력하세요"
        titleField.borderStyle = .roundedRect
        titleField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(titleField)

        contentStack.addArrangedSubview(AppStyle.label("내용", size: 15, weight: .semibold))
        bodyView.font = .systemFont(ofSize: 15)
        bodyView.textColor = AppStyle.muted
        bodyView.text = bodyPlaceholder
        bodyView.layer.cornerRadius = 12
        bodyView.layer.borderWidth = 1
        bodyView.layer.borderColor = AppStyle.line.cgColor
        bodyView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        bodyView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        bodyView.delegate = self
        contentStack.addArrangedSubview(bodyView)

        let anonymousRow = UIStackView()
        anonymousRow.axis = .horizontal
        anonymousRow.alignment = .center
        anonymousRow.addArrangedSubview(AppStyle.label("익명으로 작성", size: 15, weight: .medium))
        anonymousRow.addArrangedSubview(UIView())
        anonymousSwitch.isOn = true
        anonymousRow.addArrangedSubview(anonymousSwitch)
        contentStack.addArrangedSubview(anonymousRow)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == bodyPlaceholder {
            textView.text = ""
            textView.textColor = AppStyle.ink
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = bodyPlaceholder
            textView.textColor = AppStyle.muted
        }
    }

    @objc private func cancel() { navigationController?.popViewController(animated: true) }

    @objc private func publish() {
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text == bodyPlaceholder ? "" : bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleText.isEmpty, !bodyText.isEmpty else {
            showMessage("제목과 내용을 입력해주세요")
            return
        }
        let category = categoryControl.selectedSegmentIndex == 0 ? "질문" : "정보"
        CommunityPostStore.shared.add(title: titleText, body: bodyText, category: category, anonymous: anonymousSwitch.isOn)
        navigationController?.popViewController(animated: true)
    }
}
