import UIKit

@MainActor
final class EditProfileViewController: AppPageViewController {
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let departmentButton = UIButton(type: .system)
    private var department: String

    init() {
        department = UserProfileStore.shared.department
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "프로필 수정"
        addHeading("프로필 수정", subtitle: "학교생활에 필요한 정보를 관리해요")

        addField("이름", field: nameField, value: UserProfileStore.shared.name)
        addField("이메일", field: emailField, value: UserProfileStore.shared.email, keyboard: .emailAddress)
        contentStack.addArrangedSubview(AppStyle.label("학과", size: 14, weight: .semibold))
        departmentButton.setTitle(department + "  ⌄", for: .normal)
        departmentButton.setTitleColor(AppStyle.ink, for: .normal)
        departmentButton.contentHorizontalAlignment = .leading
        departmentButton.backgroundColor = .white
        departmentButton.layer.cornerRadius = 12
        departmentButton.layer.borderWidth = 1
        departmentButton.layer.borderColor = AppStyle.line.cgColor
        departmentButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        departmentButton.addAction(UIAction { [weak self] _ in self?.chooseDepartment() }, for: .touchUpInside)
        contentStack.addArrangedSubview(departmentButton)

        contentStack.addArrangedSubview(AppStyle.button("저장하기", primary: true) { [weak self] in self?.save() })
    }

    private func addField(_ title: String, field: UITextField, value: String, keyboard: UIKeyboardType = .default) {
        contentStack.addArrangedSubview(AppStyle.label(title, size: 14, weight: .semibold))
        field.text = value
        field.keyboardType = keyboard
        field.autocapitalizationType = .none
        field.borderStyle = .roundedRect
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        contentStack.addArrangedSubview(field)
    }

    private func chooseDepartment() {
        let sheet = UIAlertController(title: "학과 선택", message: nil, preferredStyle: .actionSheet)
        ["소프트웨어과", "인공지능과", "게임과", "스마트IoT과"].forEach { value in
            sheet.addAction(UIAlertAction(title: value, style: .default) { [weak self] _ in
                guard let self else { return }
                self.department = value
                self.departmentButton.setTitle(value + "  ⌄", for: .normal)
            })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = departmentButton
            popover.sourceRect = departmentButton.bounds
        }
        present(sheet, animated: true)
    }

    private func save() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty, email.contains("@") else {
            showMessage("이름과 이메일을 확인해주세요")
            return
        }
        UserProfileStore.shared.update(name: name, department: department, email: email)
        navigationController?.popViewController(animated: true)
    }
}
