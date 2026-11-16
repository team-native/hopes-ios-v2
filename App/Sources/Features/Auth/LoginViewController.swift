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

    let sheet = UIView()
    let sheetStack = UIStackView()
    let bottomSpacer = UIView()
    let heroTitleLabel = UILabel()
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
    var sheetStackLeadingConstraint: NSLayoutConstraint!
    var sheetStackTrailingConstraint: NSLayoutConstraint!
    var passwordGroupHeightConstraint: NSLayoutConstraint!
    var emailFieldHeightConstraint: NSLayoutConstraint!
    var passwordFieldHeightConstraint: NSLayoutConstraint!
    var titleGroupHeightConstraint: NSLayoutConstraint!
    var titleTopSpacerHeightConstraint: NSLayoutConstraint!
    var feedback: Feedback = .none
    var mode: LayoutMode = .sheet
    var keepSignedIn = UserDefaults.standard.object(forKey: "auth.keepSignedIn") as? Bool ?? true
    var keyboardObserver: NSObjectProtocol?
    var loginPreviewIsStatic = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureBackdrop()
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
        let horizontalInset: CGFloat = newMode == .sheet ? 24 : 20
        sheetStackLeadingConstraint.constant = horizontalInset
        sheetStackTrailingConstraint.constant = -horizontalInset
        keepRow.isHidden = newMode != .sheet
        signupRow.isHidden = newMode == .keyboard
        forgotButton.isHidden = newMode != .sheet
        heroTitleLabel.isHidden = newMode != .sheet
        bottomSpacer.isHidden = newMode != .full
        errorRow.isHidden = feedback != .invalidCredentials
        offlineBanner.isHidden = feedback != .offline
        sheet.layer.cornerRadius = newMode == .sheet ? 28 : 0
        sheet.layer.shadowOpacity = newMode == .sheet ? 0.06 : 0
        sheetStackTopConstraint.constant = newMode == .sheet ? 12 : (feedback == .offline ? 64 : 8)
        titleTopSpacerHeightConstraint.constant = newMode == .sheet ? 0 : 8
        titleGroupHeightConstraint.constant = newMode == .sheet ? 54 : 66
        titleGroup.layoutIfNeeded()
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

    @objc func toggleKeepSignedIn() {
        keepSignedIn.toggle()
        UserDefaults.standard.set(keepSignedIn, forKey: "auth.keepSignedIn")
        updateKeepCheckboxAppearance()
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
        let focused = UIColor(red: 142 / 255, green: 193 / 255, blue: 255 / 255, alpha: 1).cgColor
        let normal = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        emailFieldHeightConstraint.constant = textField === emailField ? 55 : 54
        passwordFieldHeightConstraint.constant = textField === passwordField ? 55 : 54
        emailField.layer.borderWidth = textField === emailField ? 1.5 : 1
        passwordField.layer.borderWidth = textField === passwordField ? 1.5 : 1
        emailField.layer.borderColor = textField === emailField ? focused : normal
        passwordField.layer.borderColor = textField === passwordField ? focused : normal
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
