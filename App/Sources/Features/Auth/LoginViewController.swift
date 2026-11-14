import UIKit

@MainActor
final class LoginViewController: UIViewController, UITextFieldDelegate {
    enum Feedback {
        case none
        case invalidCredentials
        case offline
        case loading
    }

    enum LayoutMode {
        case sheet
        case keyboard
        case full
    }

    let hero = UILabel()
    let sheet = UIView()
    let sheetStack = UIStackView()
    let titleGroup = UIStackView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let emailField = UITextField()
    let passwordField = UITextField()
    let emailGroup = UIStackView()
    let passwordGroup = UIStackView()
    let errorRow = UIStackView()
    let keepRow = UIStackView()
    let keepCheckbox = UIButton(type: .system)
    let forgotButton = UIButton(type: .system)
    let loginButton = UIButton(type: .system)
    let signupRow = UIStackView()
    let offlineBanner = UIStackView()
    let sheetTopGuide = UILayoutGuide()
    var sheetTopConstraint: NSLayoutConstraint!
    var fullTopConstraint: NSLayoutConstraint!
    var sheetBottomConstraint: NSLayoutConstraint!
    var keyboardBottomConstraint: NSLayoutConstraint!
    var sheetStackTopConstraint: NSLayoutConstraint!
    var passwordGroupHeightConstraint: NSLayoutConstraint!
    var feedback: Feedback = .none
    var mode: LayoutMode = .sheet
    var keepSignedIn = UserDefaults.standard.object(forKey: "auth.keepSignedIn") as? Bool ?? true
    var isPasswordVisible = false
    var keyboardObserver: NSObjectProtocol?
    var loginPreviewIsStatic = false

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

    func observeKeyboard() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self,
                      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
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

    func setLayoutMode(_ newMode: LayoutMode) {
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

    func applyFeedback() {
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

    @objc func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordField.isSecureTextEntry = !isPasswordVisible
        passwordField.rightView?.accessibilityLabel = isPasswordVisible ? "비밀번호 숨기기" : "비밀번호 표시"
        if let eye = passwordField.rightView as? UIButton {
            eye.setImage(UIImage(systemName: isPasswordVisible ? "eye.slash" : "eye"), for: .normal)
        }
    }

    @objc func toggleKeepSignedIn() {
        keepSignedIn.toggle()
        UserDefaults.standard.set(keepSignedIn, forKey: "auth.keepSignedIn")
        keepCheckbox.setImage(UIImage(systemName: keepSignedIn ? "checkmark.square.fill" : "square"), for: .normal)
    }

    @objc func login() {
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

    @objc func openSignUp() {
        navigationController?.pushViewController(SignupViewController(), animated: true)
    }

    @objc func openPasswordReset() {
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
