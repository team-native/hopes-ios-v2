import UIKit

@MainActor
extension LoginViewController {
    func configureBackdrop() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)

        let dimmingView = UIView()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingView)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func configureSheet() {
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 28
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.shadowColor = UIColor(red: 13 / 255, green: 26 / 255, blue: 46 / 255, alpha: 1).cgColor
        sheet.layer.shadowOpacity = 0.12
        sheet.layer.shadowRadius = 16
        sheet.layer.shadowOffset = CGSize(width: 0, height: 14)
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)
        configureSheetHandle()

        sheetStack.axis = .vertical
        sheetStack.alignment = .fill
        sheetStack.spacing = 0
        sheetStack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(sheetStack)

        titleGroup.axis = .vertical
        titleGroup.spacing = 9
        titleLabel.text = "로그인"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1)
        subtitleLabel.text = "학교 이메일로 로그인하고 바로 질문을 시작하세요."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        titleGroup.addArrangedSubview(titleLabel)
        titleGroup.addArrangedSubview(subtitleLabel)
        titleGroup.translatesAutoresizingMaskIntoConstraints = false
        titleGroup.heightAnchor.constraint(equalToConstant: 60).isActive = true
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

    private func configureSheetHandle() {
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 209 / 255, green: 222 / 255, blue: 237 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 20),
            handle.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 86),
            handle.heightAnchor.constraint(equalToConstant: 5)
        ])
    }

    func configureFields() {
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
        eye.setImage(UIImage(named: "password-eye")?.withRenderingMode(.alwaysOriginal), for: .normal)
        eye.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        eye.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        eye.accessibilityLabel = "비밀번호 표시"
        passwordField.rightView = eye
        passwordField.rightViewMode = .always

        emailGroup.axis = .vertical
        emailGroup.alignment = .leading
        emailGroup.spacing = 7
        emailGroup.addArrangedSubview(makeFieldLabel("이메일"))
        emailGroup.addArrangedSubview(emailField)
        emailGroup.heightAnchor.constraint(equalToConstant: 61).isActive = true

        passwordGroup.axis = .vertical
        passwordGroup.alignment = .leading
        passwordGroup.spacing = 9
        passwordGroup.addArrangedSubview(makeFieldLabel("비밀번호"))
        passwordGroup.addArrangedSubview(passwordField)
        passwordGroup.addArrangedSubview(errorRow)
        passwordGroupHeightConstraint = passwordGroup.heightAnchor.constraint(equalToConstant: 63)
        passwordGroupHeightConstraint.isActive = true

        sheetStack.addArrangedSubview(makeSpacer(height: 34))
        sheetStack.addArrangedSubview(emailGroup)
        sheetStack.addArrangedSubview(makeSpacer(height: 15))
        sheetStack.addArrangedSubview(passwordGroup)
        emailField.widthAnchor.constraint(equalTo: sheetStack.widthAnchor, constant: -6).isActive = true
        passwordField.widthAnchor.constraint(equalTo: sheetStack.widthAnchor, constant: -6).isActive = true
    }

    func configureField(_ field: UITextField, placeholder: String) {
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1)]
        )
        field.font = .systemFont(ofSize: 15)
        field.textColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        field.backgroundColor = .white
        field.layer.borderColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1).cgColor
        field.layer.borderWidth = 1
        field.layer.cornerRadius = 14
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func makeFieldLabel(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1)
        label.heightAnchor.constraint(equalToConstant: 14).isActive = true
        return label
    }

    func configureKeepRow() {
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
        sheet.addSubview(keepRow)
        sheet.sendSubviewToBack(keepRow)
        NSLayoutConstraint.activate([
            keepRow.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 34),
            keepRow.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -32),
            keepRow.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 371),
            keepRow.heightAnchor.constraint(equalToConstant: 20)
        ])
        sheetStack.addArrangedSubview(makeSpacer(height: 41))
    }

    func configureActions() {
        loginButton.setTitle("로그인", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        loginButton.backgroundColor = UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1)
        loginButton.layer.cornerRadius = 14
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        loginButton.accessibilityIdentifier = "login-submit"
        loginButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        sheetStack.addArrangedSubview(makeSpacer(height: 13))
        sheetStack.addArrangedSubview(loginButton)

        let prompt = UILabel()
        prompt.text = "계정이 없으신가요?"
        prompt.font = .systemFont(ofSize: 12)
        prompt.textColor = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        let signupButton = UIButton(type: .system)
        signupButton.setTitle("회원가입", for: .normal)
        signupButton.setTitleColor(UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1), for: .normal)
        signupButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        signupButton.setAttributedTitle(NSAttributedString(
            string: "회원가입",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        ), for: .normal)
        signupButton.addTarget(self, action: #selector(openSignUp), for: .touchUpInside)
        signupRow.axis = .horizontal
        signupRow.alignment = .center
        signupRow.spacing = 8
        signupRow.addArrangedSubview(prompt)
        signupRow.addArrangedSubview(signupButton)
        signupRow.translatesAutoresizingMaskIntoConstraints = false
        signupRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        sheetStack.addArrangedSubview(makeSpacer(height: 21))
        sheetStack.addArrangedSubview(signupRow)
    }

    private func makeSpacer(height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    func configureOfflineBanner() {
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

    func configureLayout() {
        view.addLayoutGuide(sheetTopGuide)
        NSLayoutConstraint.activate([
            sheetTopGuide.topAnchor.constraint(equalTo: view.topAnchor),
            sheetTopGuide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 372.0 / 874.0),
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetStack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 32),
            sheetStack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -32),
            sheetStack.bottomAnchor.constraint(lessThanOrEqualTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        sheetStackTopConstraint = sheetStack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 68)
        sheetStackTopConstraint.isActive = true
        sheetTopConstraint = sheet.topAnchor.constraint(equalTo: sheetTopGuide.bottomAnchor)
        fullTopConstraint = sheet.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
        sheetBottomConstraint = sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        keyboardBottomConstraint = sheet.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        sheetTopConstraint.isActive = true
        sheetBottomConstraint.isActive = true
    }

    func configurePreviewState() {
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

}
