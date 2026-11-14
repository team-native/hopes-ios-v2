import UIKit

@MainActor
final class SignupViewController: UIViewController, UITextFieldDelegate {
    enum Step {
        case email
        case verification
        case verified
        case password
        case passwordReady
        case profile
        case complete
    }

    enum Palette {
        static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        static let muted = UIColor(red: 111 / 255, green: 127 / 255, blue: 153 / 255, alpha: 1)
        static let line = UIColor(red: 226 / 255, green: 234 / 255, blue: 246 / 255, alpha: 1)
        static let placeholder = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        static let error = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1)
        static let paleBlue = UIColor(red: 232 / 255, green: 243 / 255, blue: 255 / 255, alpha: 1)
    }

    let topBar = UIView()
    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    let titleLabel = UILabel()
    let backButton = UIButton(type: .system)
    let actionButton = UIButton(type: .system)
    let emailField = UITextField()
    let codeField = UITextField()
    let nameField = UITextField()
    let passwordField = UITextField()
    let confirmField = UITextField()
    let codeDigits = UIStackView()
    let timerLabel = UILabel()
    let termsButton = UIButton(type: .system)
    let departmentButton = UIButton(type: .system)
    let generationButton = UIButton(type: .system)

    var step: Step = .email
    var email = ""
    var selectedDepartment = UserProfileStore.shared.department
    var generation: String?
    var termsAccepted = true
    var countdown = 300
    var countdownTimer: Timer?
    var emailError: String?
    var codeError: String?
    var passwordError: String?
    var confirmError: String?
    var generationError = true
    var sheetView: UIView?
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
        view.accessibilityIdentifier = "signup-screen"
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
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.accessibilityLabel = "뒤로 가기"
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backButton)

        titleLabel.text = "회원가입"
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
        configureTextField(emailField, placeholder: "학교 이메일(@gsm.hs.kr)", contentType: .emailAddress)
        emailField.keyboardType = .emailAddress
        emailField.text = email
        emailField.returnKeyType = .done
        emailField.delegate = self

        configureTextField(codeField, placeholder: "", contentType: .oneTimeCode, height: 56)
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

        configureTextField(nameField, placeholder: "이름", contentType: .name)
        nameField.text = UserProfileStore.shared.name
        nameField.addTarget(self, action: #selector(profileNameChanged), for: .editingChanged)

        configureTextField(passwordField, placeholder: "비밀번호", contentType: .newPassword)
        passwordField.isSecureTextEntry = true
        passwordField.delegate = self
        passwordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)

        configureTextField(confirmField, placeholder: "비밀번호 확인", contentType: .newPassword)
        confirmField.isSecureTextEntry = true
        confirmField.delegate = self
        confirmField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)

        departmentButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        generationButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

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

        departmentButton.addTarget(self, action: #selector(showDepartmentPicker), for: .touchUpInside)
        generationButton.addTarget(self, action: #selector(showGenerationPicker), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(toggleTerms), for: .touchUpInside)
    }

    func configureTextField(
        _ field: UITextField,
        placeholder: String,
        contentType: UITextContentType?,
        height: CGFloat = 44
    ) {
        field.font = .systemFont(ofSize: 15)
        field.textColor = Palette.ink
        field.backgroundColor = .white
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = Palette.line.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.attributedPlaceholder = NSAttributedString(string: placeholder,
            attributes: [.foregroundColor: Palette.placeholder])
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        if let contentType { field.textContentType = contentType }
        field.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

}
