import UIKit

@MainActor
final class PasswordResetViewController: AppPageViewController {
    private let emailField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "비밀번호 찾기"
        navigationController?.setNavigationBarHidden(false, animated: false)
        addHeading("비밀번호를 잊으셨나요?", subtitle: "가입한 학교 이메일로 재설정 안내를 보내드릴게요")

        contentStack.addArrangedSubview(AppStyle.label("학교 이메일", size: 14, weight: .semibold))
        emailField.placeholder = "이메일을 입력하세요"
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.textContentType = .emailAddress
        emailField.borderStyle = .roundedRect
        emailField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(emailField)

        contentStack.addArrangedSubview(AppStyle.button("재설정 링크 보내기", primary: true) { [weak self] in
            self?.requestReset()
        })
        contentStack.addArrangedSubview(AppStyle.label("이메일이 도착하지 않으면 스팸 메일함을 확인해주세요", size: 13, color: AppStyle.muted))
    }

    private func requestReset() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard email.contains("@"), email.contains(".") else {
            showMessage("올바른 이메일 주소를 입력해주세요")
            return
        }
        let alert = UIAlertController(title: "요청을 받았어요", message: "비밀번호 재설정 API 연결 전이라 이메일 발송은 처리되지 않았어요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
