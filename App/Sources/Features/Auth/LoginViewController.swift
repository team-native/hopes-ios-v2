import UIKit

@MainActor
final class LoginViewController: UIViewController, UITextFieldDelegate {
    private enum Feedback {
        case none
        case invalidCredentials
        case offline
        case loading
    }

    private enum LayoutMode {
        case sheet
        case keyboard
        case full
    }

    private let hero = UILabel()
    private let sheet = UIView()
    private let sheetStack = UIStackView()
    private let titleGroup = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let emailGroup = UIStackView()
    private let passwordGroup = UIStackView()
    private let errorRow = UIStackView()
    private let keepRow = UIStackView()
    private let keepCheckbox = UIButton(type: .system)
    private let forgotButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let signupRow = UIStackView()
    private let offlineBanner = UIStackView()
    private let sheetTopGuide = UILayoutGuide()
    private var sheetTopConstraint: NSLayoutConstraint!
    private var fullTopConstraint: NSLayoutConstraint!
    private var sheetBottomConstraint: NSLayoutConstraint!
    private var keyboardBottomConstraint: NSLayoutConstraint!
    private var sheetStackTopConstraint: NSLayoutConstraint!
    private var passwordGroupHeightConstraint: NSLayoutConstraint!
    private var feedback: Feedback = .none
    private var mode: LayoutMode = .sheet
    private var keepSignedIn = UserDefaults.standard.object(forKey: "auth.keepSignedIn") as? Bool ?? true
    private var isPasswordVisible = false
    private var keyboardObserver: NSObjectProtocol?
    private var loginPreviewIsStatic = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureHero()
        configureSheet()
        configureFields()
        configureKeepRow()
        configureActions()
        configureOfflineBanner()
        configureLayout()
        configurePreviewState()
        observeKeyboard()
        view.accessibilityIdentifier = "login-screen"
    }

    deinit {
        if let keyboardObserver { NotificationCenter.default.removeObserver(keyboardObserver) }
    }

    private func configureHero() {
        hero.numberOfLines = 3
        let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        let attributed = NSMutableAttributedString(
            string: "선배에게 묻는\n가장 솔직한\n학교 이야기",
            attributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: ink]
        )
        attributed.addAttribute(.foregroundColor, value: blue, range: NSRange(location: 0, length: 2))
        attributed.addAttribute(.foregroundColor, value: blue, range: NSRange(location: 8, length: 6))
        hero.attributedText = attributed
        hero.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hero)
        NSLayoutConstraint.activate([
            hero.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hero.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hero.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 72.5),
            hero.heightAnchor.constraint(equalToConstant: 114)
        ])
    }

    private func configureSheet() {
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 28
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.shadowColor = UIColor(red: 26 / 255, green: 51 / 255, blue: 102 / 255, alpha: 1).cgColor
        sheet.layer.shadowOpacity = 0.06
        sheet.layer.shadowRadius = 12
        sheet.layer.shadowOffset = CGSize(width: 0, height: -4)
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)

        sheetStack.axis = .vertical
        sheetStack.alignment = .fill
        sheetStack.spacing = 14
        sheetStack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(sheetStack)

        titleGroup.axis = .vertical
        titleGroup.spacing = 4
        titleLabel.text = "로그인"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        subtitleLabel.text = "학교 이메일로 로그인하고 바로 질문을 시작하세요."
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        titleGroup.addArrangedSubview(titleLabel)
        titleGroup.addArrangedSubview(subtitleLabel)
        titleGroup.translatesAutoresizingMaskIntoConstraints = false
        titleGroup.heightAnchor.constraint(equalToConstant: 54).isActive = true
        sheetStack.addArrangedSubview(titleGroup)

        errorRow.axis = .horizontal
        errorRow.alignment = .center
        errorRow.spacing = 4
        let errorIcon = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        errorIcon.tintColor = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1)
        errorIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        errorIcon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let errorLabel = UILabel()
        errorLabel.text = "이메일 또는 비밀번호가 맞지 않아요. 다시 확인해 주세요."
        errorLabel.font = .systemFont(ofSize: 11)
        errorLabel.textColor = errorIcon.tintColor
        errorRow.addArrangedSubview(errorIcon)
        errorRow.addArrangedSubview(errorLabel)
        errorRow.isHidden = true
        errorRow.heightAnchor.constraint(equalToConstant: 16).isActive = true
    }

    private func configureFields() {
        configureField(emailField, placeholder: "이메일")
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.returnKeyType = .next
        emailField.delegate = self

        configureField(passwordField, placeholder: "비밀번호")
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password
        passwordField.returnKeyType = .go
        passwordField.delegate = self
        let eye = UIButton(type: .system)
        eye.setImage(UIImage(systemName: "eye"), for: .normal)
        eye.tintColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        eye.frame = CGRect(x: 0, y: 0, width: 40, height: 54)
        eye.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        eye.accessibilityLabel = "비밀번호 표시"
        passwordField.rightView = eye
        passwordField.rightViewMode = .always

        emailGroup.axis = .vertical
        emailGroup.spacing = 6
        emailGroup.addArrangedSubview(makeFieldLabel("이메일"))
        emailGroup.addArrangedSubview(emailField)
        emailGroup.heightAnchor.constraint(equalToConstant: 80).isActive = true

        passwordGroup.axis = .vertical
        passwordGroup.spacing = 6
        passwordGroup.addArrangedSubview(makeFieldLabel("비밀번호"))
        passwordGroup.addArrangedSubview(passwordField)
        passwordGroup.addArrangedSubview(errorRow)
        passwordGroupHeightConstraint = passwordGroup.heightAnchor.constraint(equalToConstant: 80)
        passwordGroupHeightConstraint.isActive = true

        sheetStack.addArrangedSubview(emailGroup)
        sheetStack.addArrangedSubview(passwordGroup)
    }

    private func configureField(_ field: UITextField, placeholder: String) {
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)]
        )
        field.font = .systemFont(ofSize: 15)
        field.textColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        field.backgroundColor = .white
        field.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        field.layer.borderWidth = 1
        field.layer.cornerRadius = 16
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 54).isActive = true
    }

    private func makeFieldLabel(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }

    private func configureKeepRow() {
        keepRow.axis = .horizontal
        keepRow.alignment = .center
        keepRow.spacing = 8

        keepCheckbox.setImage(UIImage(systemName: keepSignedIn ? "checkmark.square.fill" : "square"), for: .normal)
        keepCheckbox.tintColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        keepCheckbox.addTarget(self, action: #selector(toggleKeepSignedIn), for: .touchUpInside)
        keepCheckbox.accessibilityLabel = "로그인 유지"
        keepCheckbox.widthAnchor.constraint(equalToConstant: 20).isActive = true
        keepCheckbox.heightAnchor.constraint(equalToConstant: 20).isActive = true
        keepRow.addArrangedSubview(keepCheckbox)

        let keepLabel = UILabel()
        keepLabel.text = "로그인 유지"
        keepLabel.font = .systemFont(ofSize: 12)
        keepLabel.textColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        keepRow.addArrangedSubview(keepLabel)
        keepRow.addArrangedSubview(UIView())

        forgotButton.setTitle("비밀번호 찾기", for: .normal)
        forgotButton.setTitleColor(UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1), for: .normal)
        forgotButton.titleLabel?.font = .systemFont(ofSize: 12)
        forgotButton.addTarget(self, action: #selector(openPasswordReset), for: .touchUpInside)
        keepRow.addArrangedSubview(forgotButton)
        keepRow.translatesAutoresizingMaskIntoConstraints = false
        keepRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        sheetStack.addArrangedSubview(keepRow)
    }

    private func configureActions() {
        loginButton.setTitle("로그인", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        loginButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        loginButton.accessibilityIdentifier = "login-submit"
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        sheetStack.addArrangedSubview(loginButton)

        let prompt = UILabel()
        prompt.text = "계정이 없으신가요?"
        prompt.font = .systemFont(ofSize: 12)
        prompt.textColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        let signupButton = UIButton(type: .system)
        signupButton.setTitle("회원가입", for: .normal)
        signupButton.setTitleColor(UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1), for: .normal)
        signupButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        signupButton.addTarget(self, action: #selector(openSignUp), for: .touchUpInside)
        signupRow.axis = .horizontal
        signupRow.alignment = .center
        signupRow.spacing = 8
        signupRow.addArrangedSubview(prompt)
        signupRow.addArrangedSubview(signupButton)
        signupRow.translatesAutoresizingMaskIntoConstraints = false
        signupRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        sheetStack.addArrangedSubview(signupRow)
    }

    private func configureOfflineBanner() {
        offlineBanner.axis = .horizontal
        offlineBanner.alignment = .center
        offlineBanner.spacing = 8
        offlineBanner.isLayoutMarginsRelativeArrangement = true
        offlineBanner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        offlineBanner.backgroundColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        offlineBanner.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(systemName: "wifi.slash"))
        icon.tintColor = .white
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let label = UILabel()
        label.text = "인터넷 연결이 끊겼어요. 연결되면 다시 로그인할 수 있어요."
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 1
        offlineBanner.addArrangedSubview(icon)
        offlineBanner.addArrangedSubview(label)
        offlineBanner.isHidden = true
        offlineBanner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(offlineBanner)
        NSLayoutConstraint.activate([
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            offlineBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            offlineBanner.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    private func configureLayout() {
        view.addLayoutGuide(sheetTopGuide)
        NSLayoutConstraint.activate([
            sheetTopGuide.topAnchor.constraint(equalTo: view.topAnchor),
            sheetTopGuide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 453.0 / 874.0),
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetStack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 24),
            sheetStack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -24),
            sheetStack.bottomAnchor.constraint(lessThanOrEqualTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        sheetStackTopConstraint = sheetStack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 12)
        sheetStackTopConstraint.isActive = true
        sheetTopConstraint = sheet.topAnchor.constraint(equalTo: sheetTopGuide.bottomAnchor)
        fullTopConstraint = sheet.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
        sheetBottomConstraint = sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        keyboardBottomConstraint = sheet.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        sheetTopConstraint.isActive = true
        sheetBottomConstraint.isActive = true
    }

    private func configurePreviewState() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--login-error-preview") {
            emailField.text = "s26055@gsm.hs.kr"
            passwordField.text = "password"
            feedback = .invalidCredentials
        } else if arguments.contains("--login-offline-preview") {
            emailField.text = "s26055@gsm.hs.kr"
            passwordField.text = "password"
            feedback = .offline
        } else if arguments.contains("--login-loading-preview") {
            emailField.text = "s26055@gsm.hs.kr"
            passwordField.text = "password"
            feedback = .loading
            loginPreviewIsStatic = true
        }
        applyFeedback()
    }

    private func observeKeyboard() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self,
                      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                let local = self.view.convert(frame, from: nil)
                let visible = local.minY < self.view.bounds.maxY - 1
                if visible, self.feedback == .none {
                    self.setLayoutMode(.keyboard)
                } else if !visible {
                    self.applyFeedback()
                }
            }
        }
    }

    private func setLayoutMode(_ newMode: LayoutMode) {
        mode = newMode
        sheetTopConstraint.isActive = newMode == .sheet
        fullTopConstraint.isActive = newMode != .sheet
        keyboardBottomConstraint.isActive = newMode == .keyboard
        sheetBottomConstraint.isActive = newMode != .keyboard
        hero.isHidden = newMode != .sheet
        keepRow.isHidden = newMode != .sheet
        signupRow.isHidden = newMode == .keyboard
        forgotButton.isHidden = newMode != .sheet
        errorRow.isHidden = feedback != .invalidCredentials
        offlineBanner.isHidden = feedback != .offline
        sheet.layer.cornerRadius = newMode == .sheet ? 28 : 0
        sheet.layer.shadowOpacity = newMode == .sheet ? 0.06 : 0
        sheetStackTopConstraint.constant = newMode == .keyboard ? 8 : 12
        sheet.setNeedsLayout()
        sheet.layoutIfNeeded()
    }

    private func applyFeedback() {
        switch feedback {
        case .none:
            setLayoutMode(.sheet)
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
            loginButton.setTitle("로그인", for: .normal)
        case .invalidCredentials:
            setLayoutMode(.full)
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
            loginButton.setTitle("로그인", for: .normal)
            emailField.layer.borderColor = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1).cgColor
            passwordField.layer.borderColor = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1).cgColor
        case .offline:
            setLayoutMode(.full)
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 0.38)
            loginButton.setTitle("로그인", for: .normal)
        case .loading:
            setLayoutMode(.full)
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 0.68)
            loginButton.setTitle("로그인 중...", for: .normal)
        }
        passwordGroupHeightConstraint.constant = feedback == .invalidCredentials ? 103 : 80
        errorRow.isHidden = feedback != .invalidCredentials
        offlineBanner.isHidden = feedback != .offline
    }

    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordField.isSecureTextEntry = !isPasswordVisible
        passwordField.rightView?.accessibilityLabel = isPasswordVisible ? "비밀번호 숨기기" : "비밀번호 표시"
        if let eye = passwordField.rightView as? UIButton {
            eye.setImage(UIImage(systemName: isPasswordVisible ? "eye.slash" : "eye"), for: .normal)
        }
    }

    @objc private func toggleKeepSignedIn() {
        keepSignedIn.toggle()
        UserDefaults.standard.set(keepSignedIn, forKey: "auth.keepSignedIn")
        keepCheckbox.setImage(UIImage(systemName: keepSignedIn ? "checkmark.square.fill" : "square"), for: .normal)
    }

    @objc private func login() {
        view.endEditing(true)
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              email.contains("@"),
              !(passwordField.text ?? "").isEmpty else {
            feedback = .invalidCredentials
            applyFeedback()
            return
        }
        guard feedback != .offline else { return }
        feedback = .loading
        applyFeedback()
        guard !loginPreviewIsStatic else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            let tabs = AppTabBarController()
            window.rootViewController = tabs
            window.makeKeyAndVisible()
        }
    }

    @objc private func openSignUp() {
        navigationController?.pushViewController(SignupViewController(), animated: true)
    }

    @objc private func openPasswordReset() {
        navigationController?.pushViewController(PasswordResetViewController(), animated: true)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        feedback = .none
        errorRow.isHidden = true
        emailField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        passwordField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        setLayoutMode(.keyboard)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField {
            passwordField.becomeFirstResponder()
        } else {
            login()
        }
        return true
    }
}
