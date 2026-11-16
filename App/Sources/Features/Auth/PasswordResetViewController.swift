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
        static let fieldLine = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
        static let focus = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
        static let placeholder = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        static let error = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1)
        static let paleBlue = UIColor(red: 242 / 255, green: 247 / 255, blue: 255 / 255, alpha: 1)
        static let softSurface = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
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
    var completionContentView: UIView?
    weak var passwordRequirementsStack: UIStackView?
    var fieldErrorRows: [ObjectIdentifier: UIView] = [:]
    var actionButtonConstraints: [NSLayoutConstraint] = []
    var isActionButtonInline = false
    var keyboardIsVisible = false
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

        backButton.setImage(UIImage(named: "SettingsBack"), for: .normal)
        backButton.tintColor = Palette.ink
        backButton.accessibilityLabel = "뒤로 가기"
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backButton)

        titleLabel.text = "비밀번호 찾기"
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = Palette.ink
        titleLabel.textAlignment = .left
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: Palette.ink,
            .kern: -0.2
        ]
        let titleText = NSMutableAttributedString(string: "비밀번호 찾기", attributes: titleAttributes)
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.minimumLineHeight = 26
        titleParagraph.maximumLineHeight = 26
        titleText.addAttribute(.paragraphStyle, value: titleParagraph,
                               range: NSRange(location: 0, length: titleText.length))
        titleLabel.attributedText = titleText
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
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: topBar.trailingAnchor, constant: -20),
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
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
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
        actionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        actionButton.layer.cornerRadius = 12
        actionButton.addTarget(self, action: #selector(performPrimaryAction), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionButton)
        actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        actionButtonConstraints = [
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -AppStyle.bottomActionInset)
        ]
        NSLayoutConstraint.activate(actionButtonConstraints)
    }

    func configureFields() {
        configureTextField(emailField, placeholder: "학교 이메일(@gsm.hs.kr)", height: 55)
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

        configureTextField(newPasswordField, placeholder: "새 비밀번호", height: 55)
        newPasswordField.isSecureTextEntry = true
        newPasswordField.textContentType = .newPassword
        newPasswordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)

        configureTextField(confirmPasswordField, placeholder: "새 비밀번호 확인", height: 55)
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
        timerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timerLabel.textColor = Palette.blue
    }

    func configureTextField(
        _ field: UITextField,
        placeholder: String,
        height: CGFloat = 44
    ) {
        field.attributedPlaceholder = NSAttributedString(string: placeholder,
            attributes: [.foregroundColor: Palette.placeholder])
        field.font = .systemFont(ofSize: 15)
        field.defaultTextAttributes[.kern] = -0.1
        field.textColor = Palette.ink
        field.backgroundColor = .white
        field.layer.cornerRadius = 16
        field.layer.borderWidth = 1
        field.layer.borderColor = Palette.fieldLine.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
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
        if textField === newPasswordField || textField === confirmPasswordField {
            return AuthPasswordPolicy.allowsChange(in: textField.text, range: range, replacement: string)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performPrimaryAction()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField === codeField {
            updateCodeDigitFocus()
            return
        }
        let hasError = (textField === emailField && emailError != nil)
            || (textField === newPasswordField && passwordError != nil)
            || (textField === confirmPasswordField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.focus).cgColor
        textField.layer.borderWidth = 1.5
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === codeField {
            updateCodeDigitFocus()
            return
        }
        let hasError = (textField === emailField && emailError != nil)
            || (textField === newPasswordField && passwordError != nil)
            || (textField === confirmPasswordField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.fieldLine).cgColor
        textField.layer.borderWidth = hasError ? 1.5 : 1
    }
}
