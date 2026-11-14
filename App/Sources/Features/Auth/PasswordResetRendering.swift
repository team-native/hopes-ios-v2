import UIKit

@MainActor
extension PasswordResetViewController {
    func render() {
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

    func renderEmailStep() {
        addStepper(current: 0)
        addHeading(lines: ["가입한 학교 이메일을", "입력해 주세요"])
        addField(label: "학교 이메일", field: emailField, error: emailError)
        addSpacer(24)
    }

    func renderVerificationStep() {
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

    func renderNewPasswordStep() {
        addStepper(current: 2)
        addHeading(lines: ["새 비밀번호를", "만들어 주세요"], subtitle: "이전에 쓰던 비밀번호와 다르게 만들어 주세요.")
        addField(label: "새 비밀번호", field: newPasswordField, error: passwordError, visibility: true)
        addPasswordRequirements()
        addField(label: "새 비밀번호 확인", field: confirmPasswordField, error: confirmError, visibility: true)
        addSpacer(28)
    }

    func renderCompleteStep() {
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
        content.addArrangedSubview(makeLabel("비밀번호를 바꿨어요", size: 21, weight: .bold, color: Palette.ink,
            alignment: .center))
        content.addArrangedSubview(makeLabel("새 비밀번호로 다시 로그인해 주세요.", size: 13, color: Palette.muted,
            alignment: .center))
        contentStack.addArrangedSubview(content)

        let bottom = UIView()
        bottom.heightAnchor.constraint(equalToConstant: 160).isActive = true
        contentStack.addArrangedSubview(bottom)
    }

    func addStepper(current: Int) {
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

    func addHeading(lines: [String], subtitle: String? = nil) {
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

    func addField(label: String, field: UITextField, error: String? = nil, visibility: Bool = false) {
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

    func addPasswordRequirements() {
        let value = newPasswordField.text ?? ""
        let requirements: [(String, Bool)] = [
            ("8자 이상", value.count >= 8),
            (
                "영문과 숫자 포함",
                value.rangeOfCharacter(from: .letters) != nil &&
                    value.rangeOfCharacter(from: .decimalDigits) != nil
            ),
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

    func addEmailSummary() {
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

    func makeInlineError(_ text: String) -> UIStackView {
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

    func addInlineError(_ text: String) {
        let row = makeInlineError(text)
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(row)
        addSpacer(4)
    }

    func makeLabel(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = 0
        return label
    }

    func addSpacer(_ height: CGFloat) {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    var formattedCountdown: String {
        String(format: "%02d:%02d", countdown / 60, countdown % 60)
    }

    func character(at index: Int) -> String {
        let digits = Array(codeField.text ?? "")
        return digits.indices.contains(index) ? String(digits[index]) : ""
    }

    var passwordRequirementsMet: Bool {
        let value = newPasswordField.text ?? ""
        return value.count >= 8
            && value.rangeOfCharacter(from: .letters) != nil
            && value.rangeOfCharacter(from: .decimalDigits) != nil
            && value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
    }

}
