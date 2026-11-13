import UIKit

@MainActor
final class SignupViewController: AppPageViewController {
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let confirmField = UITextField()
    private let departmentButton = UIButton(type: .system)
    private let termsSwitch = UISwitch()
    private var selectedDepartment: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "회원가입"
        navigationController?.setNavigationBarHidden(false, animated: false)
        addHeading("계정 만들기", subtitle: "학교 이메일로 Hopes를 시작해보세요")

        addField("이름", field: nameField, placeholder: "이름을 입력하세요")
        addField("학교 이메일", field: emailField, placeholder: "이메일을 입력하세요", keyboard: .emailAddress)

        contentStack.addArrangedSubview(AppStyle.label("학과", size: 14, weight: .semibold))
        departmentButton.setTitle("학과 선택  ⌄", for: .normal)
        departmentButton.setTitleColor(AppStyle.muted, for: .normal)
        departmentButton.contentHorizontalAlignment = .leading
        departmentButton.backgroundColor = .white
        departmentButton.layer.cornerRadius = 12
        departmentButton.layer.borderWidth = 1
        departmentButton.layer.borderColor = AppStyle.line.cgColor
        departmentButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        departmentButton.addAction(UIAction { [weak self] _ in self?.chooseDepartment() }, for: .touchUpInside)
        contentStack.addArrangedSubview(departmentButton)

        addField("비밀번호", field: passwordField, placeholder: "8자 이상 입력하세요", secure: true)
        addField("비밀번호 확인", field: confirmField, placeholder: "비밀번호를 다시 입력하세요", secure: true)

        let terms = UIStackView()
        terms.axis = .horizontal
        terms.alignment = .center
        terms.spacing = 10
        let termsLabel = AppStyle.label("이용약관 및 개인정보 처리에 동의합니다", size: 13)
        termsLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        terms.addArrangedSubview(termsLabel)
        terms.addArrangedSubview(UIView())
        termsSwitch.isOn = false
        terms.addArrangedSubview(termsSwitch)
        contentStack.addArrangedSubview(terms)

        contentStack.addArrangedSubview(AppStyle.button("회원가입", primary: true) { [weak self] in
            self?.submit()
        })
    }

    private func addField(_ label: String, field: UITextField, placeholder: String, keyboard: UIKeyboardType = .default, secure: Bool = false) {
        contentStack.addArrangedSubview(AppStyle.label(label, size: 14, weight: .semibold))
        field.placeholder = placeholder
        field.keyboardType = keyboard
        field.autocapitalizationType = .none
        field.isSecureTextEntry = secure
        field.borderStyle = .roundedRect
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        contentStack.addArrangedSubview(field)
    }

    private func chooseDepartment() {
        let sheet = UIAlertController(title: "학과 선택", message: nil, preferredStyle: .actionSheet)
        ["소프트웨어과", "인공지능과", "게임과", "스마트IoT과"].forEach { department in
            sheet.addAction(UIAlertAction(title: department, style: .default) { [weak self] _ in
                self?.selectedDepartment = department
                self?.departmentButton.setTitle(department + "  ⌄", for: .normal)
                self?.departmentButton.setTitleColor(AppStyle.ink, for: .normal)
            })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = departmentButton
            popover.sourceRect = departmentButton.bounds
        }
        present(sheet, animated: true)
    }

    private func submit() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let valid = !(nameField.text ?? "").isEmpty && email.contains("@") && selectedDepartment != nil
            && (passwordField.text?.count ?? 0) >= 8
            && passwordField.text == confirmField.text
            && termsSwitch.isOn
        guard valid else {
            showMessage("입력 항목과 약관 동의를 확인해주세요")
            return
        }
        let alert = UIAlertController(title: "가입 신청 완료", message: "계정 생성 API 연결 전 임시 완료 상태예요. 로그인 화면으로 돌아갑니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.setViewControllers([OnboardingViewController()], animated: true)
        })
        present(alert, animated: true)
    }
}
