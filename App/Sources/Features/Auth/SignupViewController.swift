import UIKit

@MainActor
final class SignupViewController: UIViewController, UITextFieldDelegate {
    private enum Step {
        case email
        case verification
        case verified
        case password
        case passwordReady
        case profile
        case complete
    }

    private enum Palette {
        static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        static let muted = UIColor(red: 111 / 255, green: 127 / 255, blue: 153 / 255, alpha: 1)
        static let line = UIColor(red: 226 / 255, green: 234 / 255, blue: 246 / 255, alpha: 1)
        static let placeholder = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        static let error = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1)
        static let paleBlue = UIColor(red: 232 / 255, green: 243 / 255, blue: 255 / 255, alpha: 1)
    }

    private let topBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let actionButton = UIButton(type: .system)
    private let emailField = UITextField()
    private let codeField = UITextField()
    private let nameField = UITextField()
    private let passwordField = UITextField()
    private let confirmField = UITextField()
    private let codeDigits = UIStackView()
    private let timerLabel = UILabel()
    private let termsButton = UIButton(type: .system)
    private let departmentButton = UIButton(type: .system)
    private let generationButton = UIButton(type: .system)

    private var step: Step = .email
    private var email = "s26055@gsm.hs.kr"
    private var selectedDepartment = UserProfileStore.shared.department
    private var generation: String?
    private var termsAccepted = true
    private var countdown = 300
    private var countdownTimer: Timer?
    private var emailError: String?
    private var codeError: String?
    private var passwordError: String?
    private var confirmError: String?
    private var generationError = true
    private var sheetView: UIView?
    private var keyboardObservers: [NSObjectProtocol] = []

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

    private func configureTopBar() {
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

    private func configureScrollView() {
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

    private func configureActionButton() {
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

    private func configureFields() {
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

    private func configureTextField(_ field: UITextField, placeholder: String, contentType: UITextContentType?, height: CGFloat = 44) {
        field.font = .systemFont(ofSize: 15)
        field.textColor = Palette.ink
        field.backgroundColor = .white
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = Palette.line.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: Palette.placeholder])
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        if let contentType { field.textContentType = contentType }
        field.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    private func render() {
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        switch step {
        case .email: renderEmailStep()
        case .verification: renderVerificationStep()
        case .verified: renderVerifiedStep()
        case .password: renderPasswordStep()
        case .passwordReady: renderPasswordStep()
        case .profile: renderProfileStep()
        case .complete: renderCompleteStep()
        }
        updateActionButton()
        backButton.isHidden = step == .complete
        scrollView.setContentOffset(.zero, animated: false)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch self.step {
            case .email: self.emailField.becomeFirstResponder()
            case .verification: self.codeField.becomeFirstResponder()
            case .password: self.passwordField.becomeFirstResponder()
            case .verified, .passwordReady, .profile, .complete: break
            }
        }
    }

    private func renderEmailStep() {
        addStepper(current: 0)
        addHeading(lines: ["학교 이메일로", "인증해 주세요"])
        addField(label: "학교 이메일", field: emailField, error: emailError)
        addSpacer(30)
    }

    private func renderVerificationStep() {
        codeField.isUserInteractionEnabled = true
        addStepper(current: 0)
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"])

        let emailSection = UIStackView()
        emailSection.axis = .vertical
        emailSection.spacing = 6
        emailSection.isLayoutMarginsRelativeArrangement = true
        emailSection.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        emailSection.addArrangedSubview(makeLabel("학교 이메일", size: 12, weight: .medium, color: Palette.muted))
        let emailRow = UIStackView()
        emailRow.axis = .horizontal
        emailRow.alignment = .center
        emailRow.spacing = 8
        emailRow.backgroundColor = Palette.paleBlue
        emailRow.layer.cornerRadius = 10
        emailRow.isLayoutMarginsRelativeArrangement = true
        emailRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        let address = makeLabel(email, size: 14, color: Palette.muted)
        emailRow.addArrangedSubview(address)
        emailRow.addArrangedSubview(UIView())
        let changeButton = UIButton(type: .system)
        changeButton.setTitle("변경", for: .normal)
        changeButton.setTitleColor(Palette.blue, for: .normal)
        changeButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        changeButton.addTarget(self, action: #selector(changeEmail), for: .touchUpInside)
        emailRow.addArrangedSubview(changeButton)
        emailSection.addArrangedSubview(emailRow)
        emailRow.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(emailSection)
        emailSection.translatesAutoresizingMaskIntoConstraints = false
        emailRow.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(16)

        codeDigits.arrangedSubviews.forEach { codeDigits.removeArrangedSubview($0); $0.removeFromSuperview() }
        for index in 0..<6 {
            let digitBox = UIView()
            digitBox.backgroundColor = .white
            digitBox.layer.cornerRadius = 10
            digitBox.layer.borderWidth = 1
            digitBox.layer.borderColor = codeError == nil ? Palette.line.cgColor : Palette.error.cgColor
            let digit = makeLabel(character(at: index), size: 20, weight: .semibold, color: Palette.ink)
            digit.textAlignment = .center
            digit.translatesAutoresizingMaskIntoConstraints = false
            digitBox.addSubview(digit)
            NSLayoutConstraint.activate([
                digit.centerXAnchor.constraint(equalTo: digitBox.centerXAnchor),
                digit.centerYAnchor.constraint(equalTo: digitBox.centerYAnchor)
            ])
            codeDigits.addArrangedSubview(digitBox)
        }
        codeDigits.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(codeDigits)
        codeDigits.heightAnchor.constraint(equalToConstant: 56).isActive = true
        codeField.isAccessibilityElement = true
        codeField.accessibilityLabel = "인증번호 6자리 입력"

        if let codeError { addInlineError(codeError) } else { addSpacer(12) }
        let timerRow = UIStackView()
        timerRow.axis = .horizontal
        timerRow.alignment = .center
        timerRow.spacing = 8
        timerLabel.text = "인증번호 유효 시간  \(formattedCountdown)"
        timerRow.addArrangedSubview(timerLabel)
        timerRow.addArrangedSubview(UIView())
        let resend = UIButton(type: .system)
        resend.setTitle("인증번호 다시 받기", for: .normal)
        resend.setTitleColor(Palette.blue, for: .normal)
        resend.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        resend.addTarget(self, action: #selector(resendCode), for: .touchUpInside)
        timerRow.addArrangedSubview(resend)
        contentStack.addArrangedSubview(timerRow)
        timerRow.translatesAutoresizingMaskIntoConstraints = false
        timerRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        addSpacer(10)
        contentStack.addArrangedSubview(makeLabel("메일이 안 왔다면 스팸함을 확인해 주세요.", size: 12, color: Palette.muted))
        addSpacer(28)
    }

    private func renderVerifiedStep() {
        codeField.isUserInteractionEnabled = false
        addStepper(current: 0)
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"])

        let emailRow = UIStackView()
        emailRow.axis = .vertical
        emailRow.spacing = 6
        emailRow.isLayoutMarginsRelativeArrangement = true
        emailRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        emailRow.addArrangedSubview(makeLabel("학교 이메일", size: 12, weight: .medium, color: Palette.muted))
        let address = UIView()
        address.backgroundColor = Palette.paleBlue
        address.layer.cornerRadius = 10
        let addressLabel = makeLabel(email, size: 13, color: Palette.ink)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        address.addSubview(addressLabel)
        NSLayoutConstraint.activate([
            address.heightAnchor.constraint(equalToConstant: 44),
            addressLabel.leadingAnchor.constraint(equalTo: address.leadingAnchor, constant: 14),
            addressLabel.centerYAnchor.constraint(equalTo: address.centerYAnchor)
        ])
        emailRow.addArrangedSubview(address)
        contentStack.addArrangedSubview(emailRow)
        emailRow.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(14)

        codeDigits.arrangedSubviews.forEach { codeDigits.removeArrangedSubview($0); $0.removeFromSuperview() }
        for index in 0..<6 {
            let digitBox = UIView()
            digitBox.backgroundColor = .white
            digitBox.layer.cornerRadius = 10
            digitBox.layer.borderWidth = 1
            digitBox.layer.borderColor = Palette.line.cgColor
            let digit = makeLabel(character(at: index), size: 20, weight: .semibold, color: Palette.ink)
            digit.textAlignment = .center
            digit.translatesAutoresizingMaskIntoConstraints = false
            digitBox.addSubview(digit)
            NSLayoutConstraint.activate([
                digit.centerXAnchor.constraint(equalTo: digitBox.centerXAnchor),
                digit.centerYAnchor.constraint(equalTo: digitBox.centerYAnchor)
            ])
            codeDigits.addArrangedSubview(digitBox)
        }
        contentStack.addArrangedSubview(codeDigits)
        codeDigits.heightAnchor.constraint(equalToConstant: 56).isActive = true
        addSpacer(10)

        let verified = UIStackView()
        verified.axis = .horizontal
        verified.alignment = .center
        verified.spacing = 6
        let icon = UIImageView(image: UIImage(systemName: "checkmark"))
        icon.tintColor = Palette.blue
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        verified.addArrangedSubview(icon)
        verified.addArrangedSubview(makeLabel("이메일 인증이 완료됐어요", size: 12, color: Palette.blue))
        verified.isLayoutMarginsRelativeArrangement = true
        verified.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(verified)
    }

    private func renderPasswordStep() {
        let isReady = step == .passwordReady
        passwordField.isUserInteractionEnabled = !isReady
        confirmField.isUserInteractionEnabled = !isReady
        addStepper(current: 1)
        addHeading(lines: ["로그인에 쓸", "비밀번호를 만들어 주세요"])
        addField(label: "비밀번호", field: passwordField, error: passwordError, showsVisibility: true)

        let requirements = UIStackView()
        requirements.axis = .vertical
        requirements.spacing = 6
        let value = passwordField.text ?? ""
        [
            ("8자 이상", value.count >= 8),
            ("영문과 숫자 포함", value.rangeOfCharacter(from: .letters) != nil && value.rangeOfCharacter(from: .decimalDigits) != nil),
            ("특수문자 포함", value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil)
        ].forEach { text, isValid in
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 6
            let image = UIImageView(image: UIImage(systemName: isValid ? "checkmark.circle.fill" : "circle"))
            image.tintColor = isValid ? Palette.blue : Palette.placeholder
            image.widthAnchor.constraint(equalToConstant: 14).isActive = true
            image.heightAnchor.constraint(equalToConstant: 14).isActive = true
            row.addArrangedSubview(image)
            row.addArrangedSubview(makeLabel(text, size: 12, color: isValid ? Palette.blue : Palette.muted))
            requirements.addArrangedSubview(row)
        }
        contentStack.addArrangedSubview(requirements)
        requirements.translatesAutoresizingMaskIntoConstraints = false
        requirements.heightAnchor.constraint(equalToConstant: 60).isActive = true
        addSpacer(14)
        addField(label: "비밀번호 확인", field: confirmField, error: confirmError, showsVisibility: true)
        addSpacer(28)
    }

    private func renderProfileStep() {
        addStepper(current: 2)
        addHeading(lines: ["선배에게 보여줄", "기본 정보를 알려주세요"], subtitle: "커뮤니티에는 이름 대신 기수만 표시돼요.")
        addField(label: "이름", field: nameField)

        departmentButton.configuration = dropdownConfiguration(title: selectedDepartment, error: false)
        addLabeledControl(label: "과", control: departmentButton)

        generationButton.configuration = dropdownConfiguration(title: generation ?? "기수 선택", error: generationError)
        addLabeledControl(label: "기수", control: generationButton, error: generationError ? "기수를 선택해 주세요." : nil)

        termsButton.configuration = checkboxConfiguration()
        contentStack.addArrangedSubview(termsButton)
        termsButton.translatesAutoresizingMaskIntoConstraints = false
        termsButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addSpacer(20)
    }

    private func renderCompleteStep() {
        let spacer = UIView()
        contentStack.addArrangedSubview(spacer)
        spacer.heightAnchor.constraint(equalToConstant: 150).isActive = true

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = Palette.blue
        check.widthAnchor.constraint(equalToConstant: 72).isActive = true
        check.heightAnchor.constraint(equalToConstant: 72).isActive = true
        content.addArrangedSubview(check)
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? UserProfileStore.shared.name
        content.addArrangedSubview(makeLabel("\(name)님, 가입이 끝났어요", size: 22, weight: .bold, color: Palette.ink, alignment: .center))
        let department = UserProfileStore.shared.department
        content.addArrangedSubview(makeLabel("\(department) · \(generation ?? "10기")로 가입했어요.\n이제 선배에게 무엇이든 물어보세요.", size: 14, color: Palette.muted, alignment: .center))
        contentStack.addArrangedSubview(content)

        let bottomSpace = UIView()
        contentStack.addArrangedSubview(bottomSpace)
        bottomSpace.heightAnchor.constraint(equalToConstant: 160).isActive = true
    }

    private func addStepper(current: Int) {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 9
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 0, trailing: 20)

        let bars = UIStackView()
        bars.axis = .horizontal
        bars.spacing = 4
        for index in 0..<3 {
            let bar = UIView()
            bar.backgroundColor = index <= current ? Palette.blue : Palette.line
            bar.layer.cornerRadius = 2
            bar.heightAnchor.constraint(equalToConstant: 3).isActive = true
            bars.addArrangedSubview(bar)
        }
        wrapper.addArrangedSubview(bars)
        let text = ["1 / 3 · 이메일 인증", "2 / 3 · 비밀번호 설정", "3 / 3 · 프로필"][current]
        wrapper.addArrangedSubview(makeLabel(text, size: 11, color: Palette.blue))
        contentStack.addArrangedSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addSpacer(16)
    }

    private func addHeading(lines: [String], subtitle: String? = nil) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        let title = makeLabel(lines.joined(separator: "\n"), size: 21, weight: .bold, color: Palette.ink)
        title.numberOfLines = 0
        stack.addArrangedSubview(title)
        if let subtitle {
            let description = makeLabel(subtitle, size: 12, color: Palette.muted)
            description.numberOfLines = 0
            stack.addArrangedSubview(description)
        }
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(16)
    }

    private func addField(label: String, field: UITextField, error: String? = nil, showsVisibility: Bool = false) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        group.isLayoutMarginsRelativeArrangement = true
        group.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        group.addArrangedSubview(makeLabel(label, size: 12, weight: .medium, color: Palette.muted))

        field.layer.borderColor = (error == nil ? Palette.line : Palette.error).cgColor
        if showsVisibility {
            let visibility = UIButton(type: .system)
            visibility.setImage(UIImage(systemName: field.isSecureTextEntry ? "eye" : "eye.slash"), for: .normal)
            visibility.tintColor = Palette.muted
            visibility.addAction(UIAction { [weak field] _ in
                field?.isSecureTextEntry.toggle()
                visibility.setImage(UIImage(systemName: field?.isSecureTextEntry == true ? "eye" : "eye.slash"), for: .normal)
            }, for: .touchUpInside)
            visibility.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
            field.rightView = visibility
            field.rightViewMode = .always
        }
        group.addArrangedSubview(field)
        if let error { group.addArrangedSubview(makeInlineError(error)) }
        contentStack.addArrangedSubview(group)
        group.translatesAutoresizingMaskIntoConstraints = false
    }

    private func addLabeledControl(label: String, control: UIButton, error: String? = nil) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        group.isLayoutMarginsRelativeArrangement = true
        group.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        group.addArrangedSubview(makeLabel(label, size: 12, weight: .medium, color: Palette.muted))
        group.addArrangedSubview(control)
        if let error { group.addArrangedSubview(makeInlineError(error)) }
        contentStack.addArrangedSubview(group)
        group.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(14)
    }

    private func makeInlineError(_ text: String) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = Palette.error
        icon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 12).isActive = true
        row.addArrangedSubview(icon)
        row.addArrangedSubview(makeLabel(text, size: 11, color: Palette.error))
        row.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return row
    }

    private func addInlineError(_ text: String) {
        let row = makeInlineError(text)
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(row)
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, alignment: NSTextAlignment = .left) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = 0
        return label
    }

    private func addSpacer(_ height: CGFloat) {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    private func dropdownConfiguration(title: String, error: Bool) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = title == "기수 선택" ? Palette.placeholder : Palette.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        config.background.backgroundColor = .white
        config.background.strokeColor = error ? Palette.error : Palette.line
        config.background.strokeWidth = 1
        config.background.cornerRadius = 12
        return config
    }

    private func checkboxConfiguration() -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: termsAccepted ? "checkmark.square.fill" : "square")
        config.title = "서비스 이용약관 및 개인정보 처리방침 동의 (필수)"
        config.imagePadding = 6
        config.contentInsets = .zero
        config.baseForegroundColor = Palette.muted
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 11)
            return outgoing
        }
        return config
    }

    private func character(at index: Int) -> String {
        let digits = Array(codeField.text ?? "")
        return index < digits.count ? String(digits[index]) : ""
    }

    private var formattedCountdown: String {
        String(format: "%02d:%02d", countdown / 60, countdown % 60)
    }

    private var passwordRequirementsMet: Bool {
        let value = passwordField.text ?? ""
        return value.count >= 8
            && value.rangeOfCharacter(from: .letters) != nil
            && value.rangeOfCharacter(from: .decimalDigits) != nil
            && value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
    }

    private func updateActionButton() {
        let title: String
        let enabled: Bool
        switch step {
        case .email:
            title = "인증번호 받기"
            enabled = true
        case .verification:
            title = "인증하기"
            enabled = (codeField.text?.count ?? 0) == 6 && countdown > 0
        case .verified:
            title = "다음"
            enabled = true
        case .password:
            title = "다음"
            enabled = passwordRequirementsMet && passwordField.text == confirmField.text && !(confirmField.text ?? "").isEmpty
        case .passwordReady:
            title = "다음"
            enabled = true
        case .profile:
            title = "가입 완료"
            enabled = generation != nil && termsAccepted && !(nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case .complete:
            title = "채팅 시작하기"
            enabled = true
        }
        actionButton.setTitle(title, for: .normal)
        actionButton.isEnabled = enabled
        actionButton.backgroundColor = enabled ? Palette.blue : Palette.blue.withAlphaComponent(0.38)
        actionButton.setTitleColor(.white, for: .normal)
    }

    private func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            guard let self, let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let local = self.view.convert(frame, from: nil)
            let overlap = max(0, self.view.bounds.maxY - local.minY)
            self.scrollView.contentInset.bottom = overlap + 64
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
            self.actionButton.transform = overlap > 0 ? CGAffineTransform(translationX: 0, y: -overlap) : .identity
        })
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scrollView.contentInset.bottom = 0
            self?.scrollView.verticalScrollIndicatorInsets.bottom = 0
            self?.actionButton.transform = .identity
        })
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdown = 300
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { timer.invalidate(); return }
                self.countdown = max(0, self.countdown - 1)
                if self.countdown == 0 {
                    timer.invalidate()
                    self.codeError = "인증 시간이 지났어요. 인증번호를 다시 받아 주세요."
                    self.render()
                } else {
                    self.timerLabel.text = "인증번호 유효 시간  \(self.formattedCountdown)"
                }
            }
        }
    }

    private func presentPicker(title: String, options: [String], selected: String?, completion: @escaping (String) -> Void) {
        guard sheetView == nil else { return }
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let dismiss = UIButton(type: .custom)
        dismiss.addTarget(self, action: #selector(dismissPicker), for: .touchUpInside)
        dismiss.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(dismiss)
        NSLayoutConstraint.activate([
            dismiss.topAnchor.constraint(equalTo: overlay.topAnchor),
            dismiss.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            dismiss.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            dismiss.bottomAnchor.constraint(equalTo: overlay.bottomAnchor)
        ])

        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 20
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(sheet)
        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
            sheet.heightAnchor.constraint(equalToConstant: 393)
        ])

        let handle = UIView()
        handle.backgroundColor = Palette.line
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(handle)
        let heading = makeLabel(title, size: 18, weight: .bold, color: Palette.ink)
        heading.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(heading)

        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 0
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(optionsStack)
        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 12),
            handle.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 48),
            handle.heightAnchor.constraint(equalToConstant: 5),
            heading.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            heading.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 22),
            optionsStack.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 16),
            optionsStack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            optionsStack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),
            optionsStack.bottomAnchor.constraint(lessThanOrEqualTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        options.forEach { option in
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.setTitleColor(option == selected ? Palette.blue : Palette.ink, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: option == selected ? .semibold : .regular)
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self, weak overlay] _ in
                completion(option)
                overlay?.removeFromSuperview()
                self?.sheetView = nil
                self?.render()
            }, for: .touchUpInside)
            optionsStack.addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        }
        sheetView = overlay
    }

    @objc private func goBack() {
        switch step {
        case .email:
            navigationController?.popViewController(animated: true)
        case .verification:
            step = .email
            codeError = nil
            countdownTimer?.invalidate()
            render()
        case .verified:
            step = .verification
            render()
            startCountdown()
        case .password:
            step = .verified
            render()
        case .passwordReady:
            step = .password
            render()
        case .profile:
            step = .passwordReady
            render()
        case .complete:
            break
        }
    }

    @objc private func performPrimaryAction() {
        view.endEditing(true)
        switch step {
        case .email:
            email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard email.lowercased().hasSuffix("@gsm.hs.kr") else {
                emailError = "학교 이메일(@gsm.hs.kr)만 사용할 수 있어요."
                render()
                return
            }
            if UserProfileStore.shared.isRegistered(email: email) {
                showAlreadyRegisteredNotice()
                return
            }
            emailError = nil
            step = .verification
            codeField.text = ""
            codeError = nil
            render()
            startCountdown()
        case .verification:
            guard (codeField.text ?? "").count == 6, countdown > 0 else {
                codeError = countdown == 0 ? "인증 시간이 지났어요. 인증번호를 다시 받아 주세요." : "인증번호 6자리를 입력해 주세요."
                render()
                return
            }
            step = .verified
            codeError = nil
            countdownTimer?.invalidate()
            render()
        case .verified:
            step = .password
            render()
        case .password:
            guard passwordRequirementsMet else {
                passwordError = "비밀번호 조건을 모두 맞춰 주세요."
                render()
                return
            }
            guard passwordField.text == confirmField.text else {
                confirmError = "비밀번호가 일치하지 않아요."
                render()
                return
            }
            passwordError = nil
            confirmError = nil
            step = .passwordReady
            render()
        case .passwordReady:
            step = .profile
            render()
        case .profile:
            guard generation != nil else {
                generationError = true
                render()
                return
            }
            guard termsAccepted else { return }
            let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            UserProfileStore.shared.update(name: name, department: selectedDepartment, email: email, generation: generation)
            UserProfileStore.shared.markRegistered(email: email)
            step = .complete
            countdownTimer?.invalidate()
            render()
        case .complete:
            navigationController?.setViewControllers([OnboardingViewController()], animated: true)
        }
    }

    @objc private func codeChanged() {
        let digits = String((codeField.text ?? "").filter(\.isNumber).prefix(6))
        if codeField.text != digits { codeField.text = digits }
        let labels = codeDigits.arrangedSubviews.compactMap { $0.subviews.first as? UILabel }
        for index in labels.indices { labels[index].text = character(at: index) }
        if codeError != nil {
            codeError = nil
            render()
            DispatchQueue.main.async { [weak self] in self?.codeField.becomeFirstResponder() }
        }
        updateActionButton()
    }

    @objc private func passwordChanged() {
        let password = passwordField.text ?? ""
        let confirmation = confirmField.text ?? ""
        passwordError = password.isEmpty || passwordRequirementsMet ? nil : "비밀번호 조건을 모두 맞춰 주세요."
        confirmError = confirmation.isEmpty || confirmation == password ? nil : "비밀번호가 일치하지 않아요."
        let responder = [passwordField, confirmField].first(where: \.isFirstResponder)
        render()
        DispatchQueue.main.async { responder?.becomeFirstResponder() }
    }

    @objc private func changeEmail() {
        step = .email
        codeError = nil
        countdownTimer?.invalidate()
        render()
    }

    @objc private func resendCode() {
        codeField.text = ""
        codeError = nil
        render()
        startCountdown()
    }

    @objc private func showDepartmentPicker() {
        presentPicker(title: "과 선택", options: ["소프트웨어과", "인공지능과", "게임과", "스마트IoT과"], selected: selectedDepartment) { [weak self] value in
            self?.selectedDepartment = value
        }
    }

    @objc private func showGenerationPicker() {
        presentPicker(title: "기수 선택", options: ["8기", "9기", "10기", "11기"], selected: generation) { [weak self] value in
            self?.generation = value
            self?.generationError = false
        }
    }

    @objc private func dismissPicker() {
        sheetView?.removeFromSuperview()
        sheetView = nil
    }

    @objc private func toggleTerms() {
        termsAccepted.toggle()
        termsButton.configuration = checkboxConfiguration()
        updateActionButton()
    }

    @objc private func profileNameChanged() {
        updateActionButton()
    }

    private func showAlreadyRegisteredNotice() {
        let alert = UIAlertController(title: "이미 가입된 이메일이에요", message: "이미 가입된 계정이 있어요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
            || (textField === passwordField && passwordError != nil)
            || (textField === confirmField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.blue).cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let hasError = (textField === emailField && emailError != nil)
            || (textField === passwordField && passwordError != nil)
            || (textField === confirmField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.line).cgColor
    }
}
