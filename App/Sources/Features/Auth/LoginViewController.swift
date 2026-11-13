import UIKit

@MainActor
final class LoginViewController: UIViewController, UITextFieldDelegate {
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let sheet = UIView()
    private let passwordVisibilityButton = UIButton(type: .system)

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    override var prefersHomeIndicatorAutoHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureBackdrop()
        configureSheet()
        configureForm()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func configureBackdrop() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)

        let tint = UIView()
        tint.backgroundColor = UIColor(red: 0x0D / 255, green: 0x6B / 255, blue: 0xC7 / 255, alpha: 0.55)
        tint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tint)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tint.topAnchor.constraint(equalTo: view.topAnchor),
            tint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tint.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureSheet() {
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 28
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.shadowColor = UIColor(red: 13 / 255, green: 26 / 255, blue: 46 / 255, alpha: 1).cgColor
        sheet.layer.shadowOpacity = 0.12
        sheet.layer.shadowRadius = 32
        sheet.layer.shadowOffset = CGSize(width: 0, height: 14)
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)

        let sheetTopGuide = UILayoutGuide()
        view.addLayoutGuide(sheetTopGuide)
        NSLayoutConstraint.activate([
            sheetTopGuide.topAnchor.constraint(equalTo: view.topAnchor),
            sheetTopGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetTopGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetTopGuide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 372.0 / 874.0),
            sheet.topAnchor.constraint(equalTo: sheetTopGuide.bottomAnchor),
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let handle = UIView()
        handle.backgroundColor = UIColor(red: 0xD1 / 255, green: 0xDE / 255, blue: 0xED / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.isUserInteractionEnabled = true
        handle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:))))
        sheet.addSubview(handle)

        let heading = UILabel()
        heading.text = "로그인"
        heading.font = .systemFont(ofSize: 26, weight: .bold)
        heading.textColor = UIColor(red: 0x0E / 255, green: 0x12 / 255, blue: 0x1A / 255, alpha: 1)
        heading.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(heading)

        let subtitle = UILabel()
        subtitle.text = "학교 이메일로 로그인하고 바로 질문을 시작하세요."
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = UIColor(red: 0x6B / 255, green: 0x7A / 255, blue: 0x94 / 255, alpha: 1)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(subtitle)

        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 20),
            handle.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 86),
            handle.heightAnchor.constraint(equalToConstant: 5),
            heading.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            heading.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 68),
            subtitle.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            subtitle.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 108)
        ])
    }

    private func configureForm() {
        let emailLabel = fieldLabel("이메일")
        let passwordLabel = fieldLabel("비밀번호")

        configureField(emailField, placeholder: "이메일", contentType: .username)
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.returnKeyType = .next
        emailField.delegate = self

        configureField(passwordField, placeholder: "비밀번호", contentType: .password)
        passwordField.isSecureTextEntry = true
        passwordField.returnKeyType = .go
        passwordField.delegate = self
        passwordField.rightView = passwordVisibilityButton
        passwordField.rightViewMode = .always
        passwordField.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "비밀번호 찾기", target: self, selector: #selector(openPasswordReset))
        ]

        passwordVisibilityButton.setImage(UIImage(named: "password-eye"), for: .normal)
        passwordVisibilityButton.tintColor = UIColor(red: 0x83 / 255, green: 0x8B / 255, blue: 0x91 / 255, alpha: 1)
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        passwordVisibilityButton.accessibilityLabel = "비밀번호 표시"
        passwordVisibilityButton.widthAnchor.constraint(equalToConstant: 32).isActive = true

        let loginButton = UIButton(type: .system)
        loginButton.setTitle("로그인", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        loginButton.backgroundColor = UIColor(red: 0x0D / 255, green: 0x8A / 255, blue: 0xE5 / 255, alpha: 1)
        loginButton.layer.cornerRadius = 14
        loginButton.layer.shadowColor = UIColor(red: 13 / 255, green: 26 / 255, blue: 46 / 255, alpha: 1).cgColor
        loginButton.layer.shadowOpacity = 0.12
        loginButton.layer.shadowRadius = 32
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 14)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(loginButton)

        let signUpPrompt = UILabel()
        signUpPrompt.text = "계정이 없으신가요?"
        signUpPrompt.font = .systemFont(ofSize: 13, weight: .medium)
        signUpPrompt.textColor = UIColor(red: 0x6B / 255, green: 0x7A / 255, blue: 0x94 / 255, alpha: 1)

        let signUpButton = UIButton(type: .system)
        signUpButton.setTitle("회원가입", for: .normal)
        signUpButton.setTitleColor(UIColor(red: 0x0D / 255, green: 0x8A / 255, blue: 0xE5 / 255, alpha: 1), for: .normal)
        signUpButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        signUpButton.setAttributedTitle(NSAttributedString(
            string: "회원가입",
            attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]
        ), for: .normal)
        signUpButton.addTarget(self, action: #selector(openSignUp), for: .touchUpInside)

        let signUpRow = UIStackView(arrangedSubviews: [signUpPrompt, signUpButton])
        signUpRow.axis = .horizontal
        signUpRow.alignment = .center
        signUpRow.spacing = 8
        signUpRow.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(signUpRow)

        let layout = [
            emailLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            emailLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 534),
            emailLabel.heightAnchor.constraint(equalToConstant: 14),
            emailField.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            emailField.topAnchor.constraint(equalTo: view.topAnchor, constant: 555),
            emailField.widthAnchor.constraint(equalToConstant: 332),
            emailField.heightAnchor.constraint(equalToConstant: 40),
            passwordLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            passwordLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 610),
            passwordLabel.heightAnchor.constraint(equalToConstant: 14),
            passwordField.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            passwordField.topAnchor.constraint(equalTo: view.topAnchor, constant: 633),
            passwordField.widthAnchor.constraint(equalToConstant: 332),
            passwordField.heightAnchor.constraint(equalToConstant: 40),
            loginButton.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            loginButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 727),
            loginButton.widthAnchor.constraint(equalToConstant: 338),
            loginButton.heightAnchor.constraint(equalToConstant: 46),
            signUpRow.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            signUpRow.topAnchor.constraint(equalTo: view.topAnchor, constant: 794),
            signUpRow.heightAnchor.constraint(equalToConstant: 20)
        ]
        NSLayoutConstraint.activate(layout)
    }

    private func fieldLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(red: 0x0E / 255, green: 0x12 / 255, blue: 0x1A / 255, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(label)
        return label
    }

    private func configureField(_ field: UITextField, placeholder: String, contentType: UITextContentType) {
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(red: 0x9C / 255, green: 0xAB / 255, blue: 0xC2 / 255, alpha: 1)]
        )
        field.font = .systemFont(ofSize: 15)
        field.textColor = UIColor(red: 0x6B / 255, green: 0x7A / 255, blue: 0x94 / 255, alpha: 1)
        field.backgroundColor = .white
        field.layer.borderColor = UIColor(red: 0xD9 / 255, green: 0xD9 / 255, blue: 0xD9 / 255, alpha: 1).cgColor
        field.layer.borderWidth = 1
        field.layer.cornerRadius = 14
        field.textContentType = contentType
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(field)
    }

    @objc private func togglePasswordVisibility() {
        passwordField.isSecureTextEntry.toggle()
        if passwordField.isSecureTextEntry {
            passwordVisibilityButton.setImage(UIImage(named: "password-eye"), for: .normal)
            passwordVisibilityButton.accessibilityLabel = "비밀번호 표시"
        } else {
            passwordVisibilityButton.setImage(UIImage(systemName: "eye"), for: .normal)
            passwordVisibilityButton.accessibilityLabel = "비밀번호 숨기기"
        }
    }

    @objc private func handleSheetPan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .ended,
              recognizer.translation(in: sheet).y > 48 else { return }
        navigationController?.dismiss(animated: true)
    }

    @objc private func login() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        guard email.contains("@"), !password.isEmpty else {
            showMessage("이메일과 비밀번호를 확인해주세요")
            return
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let window = appDelegate.window else { return }
        window.rootViewController = AppTabBarController()
        window.makeKeyAndVisible()
    }

    @objc private func openSignUp() {
        navigationController?.pushViewController(SignupViewController(), animated: true)
    }

    @objc private func openPasswordReset() {
        navigationController?.pushViewController(PasswordResetViewController(), animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField {
            passwordField.becomeFirstResponder()
        } else {
            login()
        }
        return true
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
