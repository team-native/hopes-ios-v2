import UIKit

@MainActor
final class PasswordResetViewController: UIViewController, UITextFieldDelegate {
    private enum Step {
        case email
        case unregistered
        case verification
        case newPassword
        case complete
    }

    private enum Palette {
        static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        static let muted = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        static let line = UIColor(red: 226 / 255, green: 234 / 255, blue: 246 / 255, alpha: 1)
        static let placeholder = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        static let error = UIColor(red: 235 / 255, green: 76 / 255, blue: 93 / 255, alpha: 1)
        static let paleBlue = UIColor(red: 242 / 255, green: 247 / 255, blue: 255 / 255, alpha: 1)
    }

    private let topBar = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let actionButton = UIButton(type: .system)
    private let emailField = UITextField()
    private let codeField = UITextField()
    private let codeDigits = UIStackView()
    private let timerLabel = UILabel()
    private let newPasswordField = UITextField()
    private let confirmPasswordField = UITextField()
    private var step: Step = .email
    private var email = UserProfileStore.shared.email
    private var emailError: String?
    private var codeError: String?
    private var passwordError: String?
    private var confirmError: String?
    private var countdown = 300
    private var countdownTimer: Timer?
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
        view.accessibilityIdentifier = "password-reset-screen"
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

    private func configureTextField(_ field: UITextField, placeholder: String, height: CGFloat = 44) {
        field.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: Palette.placeholder])
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

    private func render() {
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        switch step {
        case .email, .unregistered:
            renderEmailStep()
        case .verification:
            renderVerificationStep()
        case .newPassword:
            renderNewPasswordStep()
        case .complete:
            renderCompleteStep()
        }
        backButton.isHidden = step == .complete
        titleLabel.isHidden = step == .complete
        updateActionButton()
        scrollView.setContentOffset(.zero, animated: false)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch self.step {
            case .email: self.emailField.becomeFirstResponder()
            case .verification: self.codeField.becomeFirstResponder()
            case .unregistered, .newPassword, .complete: break
            }
        }
    }

    private func renderEmailStep() {
        addStepper(current: 0)
        addHeading(lines: ["가입한 학교 이메일을", "입력해 주세요"])
        addField(label: "학교 이메일", field: emailField, error: emailError)
        addSpacer(24)
    }

    private func renderVerificationStep() {
        addStepper(current: 1)
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"])
        addEmailSummary()
        addSpacer(14)
        codeDigits.arrangedSubviews.forEach { codeDigits.removeArrangedSubview($0); $0.removeFromSuperview() }
        for index in 0..<6 {
            let box = UIView()
            box.backgroundColor = .white
            box.layer.cornerRadius = 10
            box.layer.borderWidth = 1
            box.layer.borderColor = codeError == nil ? Palette.line.cgColor : Palette.error.cgColor
            let digit = makeLabel(character(at: index), size: 20, weight: .semibold, color: Palette.ink)
            digit.textAlignment = .center
            digit.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(digit)
            NSLayoutConstraint.activate([
                digit.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                digit.centerYAnchor.constraint(equalTo: box.centerYAnchor)
            ])
            codeDigits.addArrangedSubview(box)
        }
        contentStack.addArrangedSubview(codeDigits)
        codeDigits.translatesAutoresizingMaskIntoConstraints = false
        codeDigits.heightAnchor.constraint(equalToConstant: 56).isActive = true
        if let codeError { addInlineError(codeError) } else { addSpacer(10) }

        let timerRow = UIStackView()
        timerRow.axis = .horizontal
        timerRow.alignment = .center
        timerLabel.text = formattedCountdown
        timerRow.addArrangedSubview(timerLabel)
        timerRow.addArrangedSubview(UIView())
        let resend = UIButton(type: .system)
        resend.setTitle("인증번호 다시 받기", for: .normal)
        resend.setTitleColor(Palette.blue, for: .normal)
        resend.titleLabel?.font = .systemFont(ofSize: 12)
        resend.addTarget(self, action: #selector(resendCode), for: .touchUpInside)
        timerRow.addArrangedSubview(resend)
        contentStack.addArrangedSubview(timerRow)
        timerRow.translatesAutoresizingMaskIntoConstraints = false
        timerRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        addSpacer(18)
    }

    private func renderNewPasswordStep() {
        addStepper(current: 2)
        addHeading(lines: ["새 비밀번호를", "만들어 주세요"], subtitle: "이전에 쓰던 비밀번호와 다르게 만들어 주세요.")
        addField(label: "새 비밀번호", field: newPasswordField, error: passwordError, visibility: true)
        addPasswordRequirements()
        addField(label: "새 비밀번호 확인", field: confirmPasswordField, error: confirmError, visibility: true)
        addSpacer(28)
    }

    private func renderCompleteStep() {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 160).isActive = true
        contentStack.addArrangedSubview(spacer)

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        let lock = UIImageView(image: UIImage(systemName: "lock"))
        lock.tintColor = Palette.blue
        lock.backgroundColor = Palette.paleBlue
        lock.layer.cornerRadius = 36
        lock.contentMode = .center
        lock.widthAnchor.constraint(equalToConstant: 72).isActive = true
        lock.heightAnchor.constraint(equalToConstant: 72).isActive = true
        content.addArrangedSubview(lock)
        content.addArrangedSubview(makeLabel("비밀번호를 바꿨어요", size: 21, weight: .bold, color: Palette.ink, alignment: .center))
        content.addArrangedSubview(makeLabel("새 비밀번호로 다시 로그인해 주세요.", size: 13, color: Palette.muted, alignment: .center))
        contentStack.addArrangedSubview(content)

        let bottom = UIView()
        bottom.heightAnchor.constraint(equalToConstant: 160).isActive = true
        contentStack.addArrangedSubview(bottom)
    }

    private func addStepper(current: Int) {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 8
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
        let stepTitle = ["1 / 3 · 이메일 인증", "2 / 3 · 인증번호 확인", "3 / 3 · 새 비밀번호"][current]
        wrapper.addArrangedSubview(makeLabel(stepTitle, size: 11, color: Palette.blue))
        contentStack.addArrangedSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.heightAnchor.constraint(equalToConstant: 34).isActive = true
        addSpacer(14)
    }

    private func addHeading(lines: [String], subtitle: String? = nil) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        stack.addArrangedSubview(makeLabel(lines.joined(separator: "\n"), size: 21, weight: .bold, color: Palette.ink))
        if let subtitle { stack.addArrangedSubview(makeLabel(subtitle, size: 12, color: Palette.muted)) }
        contentStack.addArrangedSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(16)
    }

    private func addField(label: String, field: UITextField, error: String? = nil, visibility: Bool = false) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        group.isLayoutMarginsRelativeArrangement = true
        group.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        group.addArrangedSubview(makeLabel(label, size: 12, weight: .medium, color: Palette.muted))
        field.layer.borderColor = (error == nil ? Palette.line : Palette.error).cgColor
        if visibility {
            let eye = UIButton(type: .system)
            eye.setImage(UIImage(systemName: field.isSecureTextEntry ? "eye" : "eye.slash"), for: .normal)
            eye.tintColor = Palette.muted
            eye.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
            eye.addAction(UIAction { [weak field] _ in
                field?.isSecureTextEntry.toggle()
                (field?.rightView as? UIButton)?.setImage(
                    UIImage(systemName: field?.isSecureTextEntry == true ? "eye" : "eye.slash"),
                    for: .normal
                )
            }, for: .touchUpInside)
            field.rightView = eye
            field.rightViewMode = .always
        }
        group.addArrangedSubview(field)
        if let error { group.addArrangedSubview(makeInlineError(error)) }
        contentStack.addArrangedSubview(group)
        group.translatesAutoresizingMaskIntoConstraints = false
    }

    private func addPasswordRequirements() {
        let value = newPasswordField.text ?? ""
        let requirements: [(String, Bool)] = [
            ("8자 이상", value.count >= 8),
            ("영문과 숫자 포함", value.rangeOfCharacter(from: .letters) != nil && value.rangeOfCharacter(from: .decimalDigits) != nil),
            ("특수문자 포함", value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil)
        ]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        for (text, isValid) in requirements {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 6
            let icon = UIImageView(image: UIImage(systemName: isValid ? "checkmark.circle.fill" : "circle"))
            icon.tintColor = isValid ? Palette.blue : Palette.placeholder
            icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
            row.addArrangedSubview(icon)
            row.addArrangedSubview(makeLabel(text, size: 12, color: isValid ? Palette.blue : Palette.muted))
            stack.addArrangedSubview(row)
        }
        contentStack.addArrangedSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.heightAnchor.constraint(equalToConstant: 60).isActive = true
        addSpacer(14)
    }

    private func addEmailSummary() {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 6
        section.isLayoutMarginsRelativeArrangement = true
        section.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        section.addArrangedSubview(makeLabel("학교 이메일", size: 12, weight: .medium, color: Palette.muted))

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.backgroundColor = Palette.paleBlue
        row.layer.cornerRadius = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        row.addArrangedSubview(makeLabel(email, size: 13, color: Palette.ink))
        row.addArrangedSubview(UIView())
        let change = UIButton(type: .system)
        change.setTitle("변경", for: .normal)
        change.setTitleColor(Palette.blue, for: .normal)
        change.titleLabel?.font = .systemFont(ofSize: 12)
        change.addTarget(self, action: #selector(changeEmail), for: .touchUpInside)
        row.addArrangedSubview(change)
        section.addArrangedSubview(row)
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        section.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(section)
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
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(row)
        addSpacer(4)
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

    private var formattedCountdown: String {
        String(format: "%02d:%02d", countdown / 60, countdown % 60)
    }

    private func character(at index: Int) -> String {
        let digits = Array(codeField.text ?? "")
        return digits.indices.contains(index) ? String(digits[index]) : ""
    }

    private var passwordRequirementsMet: Bool {
        let value = newPasswordField.text ?? ""
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
        case .unregistered:
            title = "인증번호 받기"
            enabled = false
        case .verification:
            title = "확인"
            enabled = (codeField.text?.count ?? 0) == 6 && countdown > 0
        case .newPassword:
            title = "비밀번호 변경"
            enabled = passwordRequirementsMet
                && newPasswordField.text == confirmPasswordField.text
                && !(confirmPasswordField.text ?? "").isEmpty
        case .complete:
            title = "로그인하기"
            enabled = true
        }
        actionButton.setTitle(title, for: .normal)
        actionButton.isEnabled = enabled
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = enabled ? Palette.blue : Palette.blue.withAlphaComponent(0.38)
    }

    private func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                let local = self.view.convert(frame, from: nil)
                let overlap = max(0, self.view.bounds.maxY - local.minY)
                self.scrollView.contentInset.bottom = overlap + 64
                self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
                self.actionButton.transform = overlap > 0 ? CGAffineTransform(translationX: 0, y: -overlap) : .identity
            }
        })
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scrollView.contentInset.bottom = 0
                self?.scrollView.verticalScrollIndicatorInsets.bottom = 0
                self?.actionButton.transform = .identity
            }
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
                    self.timerLabel.text = self.formattedCountdown
                }
            }
        }
    }

    @objc private func goBack() {
        switch step {
        case .email, .unregistered:
            navigationController?.popViewController(animated: true)
        case .verification:
            step = .email
            countdownTimer?.invalidate()
        case .newPassword:
            step = .verification
            startCountdown()
        case .complete:
            break
        }
        render()
    }

    @objc private func performPrimaryAction() {
        view.endEditing(true)
        switch step {
        case .email, .unregistered:
            email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard email.lowercased().hasSuffix("@gsm.hs.kr") else {
                emailError = "학교 이메일(@gsm.hs.kr)만 사용할 수 있어요."
                step = .email
                render()
                return
            }
            guard UserProfileStore.shared.isRegistered(email: email) else {
                emailError = "가입되지 않은 이메일이에요. 회원가입을 먼저 진행해 주세요."
                step = .unregistered
                render()
                return
            }
            emailError = nil
            codeError = nil
            codeField.text = ""
            step = .verification
            render()
            startCountdown()
        case .verification:
            guard (codeField.text ?? "").count == 6, countdown > 0 else {
                codeError = countdown > 0 ? "인증번호 6자리를 입력해 주세요." : "인증 시간이 지났어요. 인증번호를 다시 받아 주세요."
                render()
                return
            }
            step = .newPassword
            codeError = nil
            countdownTimer?.invalidate()
            render()
        case .newPassword:
            passwordError = passwordRequirementsMet ? nil : "비밀번호 조건을 모두 맞춰 주세요."
            confirmError = newPasswordField.text == confirmPasswordField.text ? nil : "비밀번호가 일치하지 않아요."
            guard passwordError == nil, confirmError == nil else {
                render()
                return
            }
            step = .complete
            countdownTimer?.invalidate()
            render()
        case .complete:
            navigationController?.popToRootViewController(animated: true)
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
        let responder = [newPasswordField, confirmPasswordField].first(where: \.isFirstResponder)
        let password = newPasswordField.text ?? ""
        let confirmation = confirmPasswordField.text ?? ""
        passwordError = password.isEmpty || passwordRequirementsMet ? nil : "비밀번호 조건을 모두 맞춰 주세요."
        confirmError = confirmation.isEmpty || password == confirmation ? nil : "비밀번호가 일치하지 않아요."
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
