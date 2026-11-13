import UIKit

@MainActor
final class EmailVerificationViewController: AppPageViewController, UITextFieldDelegate {
    let email: String
    var onVerified: (() -> Void)?
    private let codeField = UITextField()

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "이메일 인증"
        addHeading("이메일을 확인해주세요", subtitle: "인증번호를 입력해 가입을 계속해요")
        contentStack.addArrangedSubview(AppStyle.label(email, size: 14, weight: .semibold, color: AppStyle.blue))

        codeField.placeholder = "인증번호 6자리"
        codeField.keyboardType = .numberPad
        codeField.textContentType = .oneTimeCode
        codeField.textAlignment = .center
        codeField.font = .systemFont(ofSize: 20, weight: .semibold)
        codeField.borderStyle = .roundedRect
        codeField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        codeField.delegate = self
        contentStack.addArrangedSubview(codeField)

        let resend = UIButton(type: .system)
        resend.setTitle("인증번호 다시 보내기", for: .normal)
        resend.setTitleColor(AppStyle.blue, for: .normal)
        resend.addAction(UIAction { [weak self] _ in
            self?.showVerificationNotice("인증 메일 재전송 API는 연결되지 않았어요")
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(resend)

        contentStack.addArrangedSubview(AppStyle.button("인증하기", primary: true) { [weak self] in
            self?.verify()
        })
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: stringRange, with: string)
        return updated.count <= 6 && updated.allSatisfy(\.isNumber)
    }

    private func verify() {
        guard codeField.text?.count == 6 else {
            showVerificationNotice("인증번호 6자리를 입력해주세요")
            return
        }
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.onVerified?()
        }
    }

    private func showVerificationNotice(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
