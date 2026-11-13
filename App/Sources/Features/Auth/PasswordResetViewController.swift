import UIKit

@MainActor
final class PasswordResetViewController: UIViewController, UITextFieldDelegate {
    enum Step {
        case email
        case unregistered
        case verification
        case newPassword
        case complete
    }

    enum Palette {
        static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        static let muted = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        static let line = UIColor(red: 226 / 255, green: 234 / 255, blue: 246 / 255, alpha: 1)
        static let placeholder = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        static let error = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1)
        static let paleBlue = UIColor(red: 242 / 255, green: 247 / 255, blue: 255 / 255, alpha: 1)
    }

    let topBar = UIView()
    let titleLabel = UILabel()
    let backButton = UIButton(type: .system)
    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    let actionButton = UIButton(type: .system)
    let emailField = UITextField()
    let codeField = UITextField()
    let codeDigits = UIStackView()
    let timerLabel = UILabel()
    let newPasswordField = UITextField()
    let confirmPasswordField = UITextField()
    var step: Step = .email
    var email = UserProfileStore.shared.email
    var emailError: String?
    var codeError: String?
    var passwordError: String?
    var confirmError: String?
    var countdown = 300
    var countdownTimer: Timer?
    var keyboardObservers: [NSObjectProtocol] = []

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureTopBar()
        configureScrollView()
        configureActionButton()
        configureFields()
        render()
        observeKeyboard()
        view.accessibilityIdentifier = "password-reset-screen"
    }

    deinit {
        countdownTimer?.invalidate()
        keyboardObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func configureTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = Palette.ink
        backButton.accessibilityLabel = "뒤로 가기"
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backButton)

        titleLabel.text = "비밀번호 찾기"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = Palette.ink
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 56),
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
    }

    func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    func configureActionButton() {
        actionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        actionButton.layer.cornerRadius = 12
        actionButton.addTarget(self, action: #selector(performPrimaryAction), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            actionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func configureFields() {
        configureTextField(emailField, placeholder: "학교 이메일(@gsm.hs.kr)")
        emailField.text = email
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.delegate = self
        emailField.returnKeyType = .done

        configureTextField(codeField, placeholder: "", height: 56)
        codeField.keyboardType = .numberPad
        codeField.textContentType = .oneTimeCode
        codeField.textColor = .clear
        codeField.tintColor = .clear
        codeField.backgroundColor = .clear
        codeField.layer.borderWidth = 0
        codeField.leftView = nil
        codeField.leftViewMode = .never
        codeField.delegate = self
        codeField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)

        configureTextField(newPasswordField, placeholder: "새 비밀번호")
        newPasswordField.isSecureTextEntry = true
        newPasswordField.textContentType = .newPassword
        newPasswordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)

        configureTextField(confirmPasswordField, placeholder: "새 비밀번호 확인")
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.textContentType = .newPassword
        confirmPasswordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)

        codeDigits.axis = .horizontal
        codeDigits.alignment = .fill
        codeDigits.distribution = .fillEqually
        codeDigits.spacing = 8
        codeField.translatesAutoresizingMaskIntoConstraints = false
        codeDigits.addSubview(codeField)
        NSLayoutConstraint.activate([
            codeField.leadingAnchor.constraint(equalTo: codeDigits.leadingAnchor),
            codeField.trailingAnchor.constraint(equalTo: codeDigits.trailingAnchor),
            codeField.topAnchor.constraint(equalTo: codeDigits.topAnchor),
            codeField.bottomAnchor.constraint(equalTo: codeDigits.bottomAnchor)
        ])
        timerLabel.font = .systemFont(ofSize: 12)
        timerLabel.textColor = Palette.muted
    }

    func configureTextField(
        _ field: UITextField,
        placeholder: String,
        height: CGFloat = 44
    ) {
        field.attributedPlaceholder = NSAttributedString(string: placeholder,
            attributes: [.foregroundColor: Palette.placeholder])
        field.font = .systemFont(ofSize: 15)
        field.textColor = Palette.ink
        field.backgroundColor = .white
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = Palette.line.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if textField === codeField {
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: swiftRange, with: string)
            return updated.count <= 6 && updated.allSatisfy(\.isNumber)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performPrimaryAction()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let hasError = (textField === emailField && emailError != nil)
            || (textField === newPasswordField && passwordError != nil)
            || (textField === confirmPasswordField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.blue).cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let hasError = (textField === emailField && emailError != nil)
            || (textField === newPasswordField && passwordError != nil)
            || (textField === confirmPasswordField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.line).cgColor
    }
}
