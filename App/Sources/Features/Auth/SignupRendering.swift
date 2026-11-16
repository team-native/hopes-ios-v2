import UIKit

@MainActor
extension SignupViewController {
    func render(focusField: Bool = true) {
        actionTopSpacerHeightConstraint?.isActive = false
        emailErrorRow = nil
        actionTopSpacer = nil
        actionTopSpacerHeightConstraint = nil
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        renderCurrentStep()
        if step != .complete {
            let actionTopSpacer = UIView()
            let spacerHeightConstraint = actionTopSpacer.heightAnchor.constraint(equalToConstant: 14)
            spacerHeightConstraint.isActive = true
            self.actionTopSpacer = actionTopSpacer
            actionTopSpacerHeightConstraint = spacerHeightConstraint
            contentStack.addArrangedSubview(actionTopSpacer)
        }
        if step != .complete {
            let actionContainer = UIStackView(arrangedSubviews: [actionButton])
            actionContainer.axis = .vertical
            contentStack.addArrangedSubview(actionContainer)
            let actionBottomSpacer = UIView()
            actionBottomSpacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
            contentStack.addArrangedSubview(actionBottomSpacer)
        }
        updateActionButton()
        topBar.isHidden = step == .complete
        if step == .complete {
            scrollTopToBarConstraint.isActive = false
            scrollTopToSafeAreaConstraint.isActive = true
        } else {
            scrollTopToSafeAreaConstraint.isActive = false
            scrollTopToBarConstraint.isActive = true
        }
        scrollView.setContentOffset(.zero, animated: false)
        let willFocusInput: Bool
        switch step {
        case .email, .verification, .password:
            willFocusInput = focusField
        case .verified, .passwordReady, .profile, .complete:
            willFocusInput = false
        }
        updateActionSpacer(keyboardVisible: willFocusInput)
        if focusField {
            focusFieldForCurrentStep()
        }
    }

    private func renderCurrentStep() {
        switch step {
        case .email: renderEmailStep()
        case .verification: renderVerificationStep()
        case .verified: renderVerifiedStep()
        case .password: renderPasswordStep()
        case .passwordReady: renderPasswordStep()
        case .profile: renderProfileStep()
        case .complete: renderCompleteStep()
        }
    }

    private func focusFieldForCurrentStep() {
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

    func renderEmailStep() {
        addStepper(current: 0)
        addHeading(lines: ["학교 이메일로", "인증해 주세요"], accentPrefix: "학교 이메일")
        addField(label: "학교 이메일", field: emailField, error: emailError)
    }

}

@MainActor
extension SignupViewController {
    func renderVerificationStep() {
        codeField.isUserInteractionEnabled = true
        addStepper(current: 0)
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"], accentPrefix: "인증번호")

        addVerificationEmailRow()

        addVerificationCodeDigits()

        addVerificationTimerRow()
    }

    private func addVerificationEmailRow() {
        let emailSection = UIStackView()
        emailSection.axis = .vertical
        emailSection.spacing = 6
        let emailLabel = makeLabel("학교 이메일", size: 14, weight: .medium, color: Palette.muted)
        emailLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        emailSection.addArrangedSubview(emailLabel)
        let emailRow = UIStackView()
        emailRow.axis = .horizontal
        emailRow.alignment = .center
        emailRow.spacing = 8
        emailRow.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        emailRow.layer.cornerRadius = 16
        emailRow.layer.borderWidth = 1
        emailRow.layer.borderColor = Palette.line.cgColor
        emailRow.isLayoutMarginsRelativeArrangement = true
        emailRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        let address = makeLabel(email, size: 15, color: Palette.ink)
        emailRow.addArrangedSubview(address)
        emailRow.addArrangedSubview(UIView())
        let changeButton = UIButton(type: .system)
        changeButton.setTitle("변경", for: .normal)
        changeButton.setTitleColor(Palette.blue, for: .normal)
        changeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        changeButton.addTarget(self, action: #selector(changeEmail), for: .touchUpInside)
        emailRow.addArrangedSubview(changeButton)
        emailSection.addArrangedSubview(emailRow)
        emailRow.heightAnchor.constraint(equalToConstant: 54).isActive = true
        contentStack.addArrangedSubview(emailSection)
        emailSection.translatesAutoresizingMaskIntoConstraints = false
        emailRow.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(14)
    }

    private func addVerificationCodeDigits() {
        codeDigits.arrangedSubviews.forEach { codeDigits.removeArrangedSubview($0); $0.removeFromSuperview() }
        for index in 0..<6 {
            let digitBox = UIView()
            digitBox.backgroundColor = .white
            digitBox.layer.cornerRadius = 16
            digitBox.layer.borderWidth = 1
            digitBox.layer.borderColor = codeError == nil ? Palette.line.cgColor : Palette.error.cgColor
            let digit = makeLabel(character(at: index), size: 22, weight: .bold, color: Palette.ink)
            digit.textAlignment = .center
            digit.attributedText = NSAttributedString(string: character(at: index), attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: Palette.ink,
                .kern: -0.3
            ])
            digit.translatesAutoresizingMaskIntoConstraints = false
            digitBox.addSubview(digit)
            NSLayoutConstraint.activate([
                digit.centerXAnchor.constraint(equalTo: digitBox.centerXAnchor),
                digit.centerYAnchor.constraint(equalTo: digitBox.centerYAnchor)
            ])
            codeDigits.addArrangedSubview(digitBox)
        }
        codeDigits.translatesAutoresizingMaskIntoConstraints = false
        codeDigits.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let codeLabel = makeLabel("인증번호 6자리", size: 14, weight: .medium, color: Palette.muted)
        codeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let codeSection = UIStackView(arrangedSubviews: [codeLabel, codeDigits])
        codeSection.axis = .vertical
        codeSection.spacing = 8
        contentStack.addArrangedSubview(codeSection)
        codeField.isAccessibilityElement = true
        codeField.accessibilityLabel = "인증번호 6자리 입력"
        updateVerificationDigitAppearance()
    }

    func updateVerificationDigitAppearance() {
        let activeIndex = min((codeField.text ?? "").count, 5)
        for (index, digitBox) in codeDigits.arrangedSubviews.enumerated() {
            if codeError != nil && countdown > 0 {
                digitBox.layer.borderColor = Palette.error.cgColor
                digitBox.layer.borderWidth = 1.5
            } else if countdown == 0 && index == 0 {
                digitBox.layer.borderColor = Palette.line.cgColor
                digitBox.layer.borderWidth = 1.5
            } else if codeField.isFirstResponder && index == activeIndex && (codeField.text ?? "").count < 6 {
                digitBox.layer.borderColor = Palette.focus.cgColor
                digitBox.layer.borderWidth = 1.5
            } else {
                digitBox.layer.borderColor = Palette.line.cgColor
                digitBox.layer.borderWidth = 1
            }
        }
    }

    private func addVerificationTimerRow() {
        if let codeError {
            addSpacer(8)
            addInlineError(codeError)
            addSpacer(14)
        } else {
            addSpacer(14)
        }
        let timerRow = UIStackView()
        timerRow.axis = .horizontal
        timerRow.alignment = .center
        timerRow.spacing = 8
        timerLabel.text = formattedCountdown
        timerLabel.textColor = countdown == 0 ? Palette.error : Palette.blue
        timerLabel.accessibilityLabel = "인증번호 유효 시간 \(formattedCountdown)"
        let clockIcon = UIImageView(image: UIImage(named: "PasswordResetClock")?.withRenderingMode(.alwaysTemplate))
        clockIcon.tintColor = countdown == 0 ? Palette.error : Palette.blue
        clockIcon.contentMode = .scaleAspectFit
        clockIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        clockIcon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let timer = UIStackView(arrangedSubviews: [clockIcon, timerLabel])
        timer.axis = .horizontal
        timer.alignment = .center
        timer.spacing = 6
        timerRow.addArrangedSubview(timer)
        timerRow.addArrangedSubview(UIView())
        let resend = UIButton(type: .system)
        resend.setTitle("인증번호 다시 받기", for: .normal)
        resend.setTitleColor(Palette.muted, for: .normal)
        resend.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        resend.addTarget(self, action: #selector(resendCode), for: .touchUpInside)
        timerRow.addArrangedSubview(resend)
        contentStack.addArrangedSubview(timerRow)
        timerRow.translatesAutoresizingMaskIntoConstraints = false
        timerRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        if codeError == nil {
            addSpacer(14)
            contentStack.addArrangedSubview(makeLabel("메일이 안 왔다면 스팸함을 확인해 주세요.", size: 12, color: Palette.muted))
        }
    }

}

@MainActor
extension SignupViewController {
    func renderVerifiedStep() {
        codeField.isUserInteractionEnabled = false
        addStepper(current: 0)
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"], accentPrefix: "인증번호")

        addVerificationEmailRow()

        addVerificationCodeDigits()
        addSpacer(14)

        addVerifiedConfirmation()
    }

    private func addVerifiedConfirmation() {
        let verified = UIStackView()
        verified.axis = .horizontal
        verified.alignment = .center
        verified.spacing = 6
        let icon = UIImageView(image: UIImage(systemName: "checkmark"))
        icon.tintColor = Palette.blue
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        verified.addArrangedSubview(icon)
        verified.addArrangedSubview(makeLabel("이메일 인증이 완료됐어요", size: 14, weight: .medium, color: Palette.blue))
        contentStack.addArrangedSubview(verified)
    }

    func renderPasswordStep() {
        let isReady = step == .passwordReady
        passwordField.isUserInteractionEnabled = !isReady
        confirmField.isUserInteractionEnabled = !isReady
        confirmFieldHeightConstraint?.constant = confirmError == nil ? 54 : 55
        addStepper(current: 1)
        addHeading(lines: ["로그인에 쓸", "비밀번호를 만들어 주세요"], accentPrefix: "비밀번호")
        addField(label: "비밀번호", field: passwordField, error: passwordError, showsVisibility: true)
        addSpacer(14)

        let requirements = UIStackView()
        requirements.axis = .vertical
        requirements.spacing = 6
        for _ in 0..<3 {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 6
            let image = UIImageView()
            image.widthAnchor.constraint(equalToConstant: 14).isActive = true
            image.heightAnchor.constraint(equalToConstant: 14).isActive = true
            row.addArrangedSubview(image)
            row.addArrangedSubview(makeLabel("", size: 12, color: Palette.placeholder))
            requirements.addArrangedSubview(row)
        }
        passwordRequirementsStack = requirements
        updatePasswordRequirementRows()
        contentStack.addArrangedSubview(requirements)
        requirements.translatesAutoresizingMaskIntoConstraints = false
        requirements.heightAnchor.constraint(equalToConstant: 60).isActive = true
        addSpacer(14)
        addField(label: "비밀번호 확인", field: confirmField, error: confirmError)
    }

    func renderProfileStep() {
        addStepper(current: 2)
        addHeading(lines: ["선배에게 보여줄", "기본 정보를 알려주세요"], subtitle: "커뮤니티에는 이름 대신 기수만 표시돼요.", accentPrefix: "선배")
        addField(label: "이름", field: nameField)
        addSpacer(14)

        departmentButton.configuration = dropdownConfiguration(title: selectedDepartment, error: false)
        addLabeledControl(label: "과", control: departmentButton)

        generationButton.configuration = dropdownConfiguration(title: generation ?? "기수 선택", error: generationError)
        addLabeledControl(label: "기수", control: generationButton, error: generationError ? "기수를 선택해 주세요." : nil)

        termsButton.configuration = checkboxConfiguration()
        termsButton.contentHorizontalAlignment = .leading
        contentStack.addArrangedSubview(termsButton)
        termsButton.translatesAutoresizingMaskIntoConstraints = false
        termsButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        addSpacer(20)
    }

    func character(at index: Int) -> String {
        let digits = Array(codeField.text ?? "")
        return index < digits.count ? String(digits[index]) : ""
    }

    var formattedCountdown: String {
        String(format: "%02d:%02d", countdown / 60, countdown % 60)
    }

    var passwordRequirementStates: [(String, Bool)] {
        let value = passwordField.text ?? ""
        return [
            ("8자 이상", value.count >= 8),
            (
                "영문과 숫자 포함",
                value.rangeOfCharacter(from: .letters) != nil &&
                    value.rangeOfCharacter(from: .decimalDigits) != nil
            ),
            ("특수문자 포함", value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil)
        ]
    }

    func updatePasswordRequirementRows() {
        guard let rows = passwordRequirementsStack?.arrangedSubviews as? [UIStackView] else { return }
        for (row, state) in zip(rows, passwordRequirementStates) {
            let (text, isValid) = state
            let showsError = passwordError != nil && !isValid
            let imageName = showsError ? "SignupRuleX" : (isValid ? "SignupRuleCheck" : "SignupRuleCheckMuted")
            (row.arrangedSubviews.first as? UIImageView)?.image = UIImage(named: imageName)?
                .withRenderingMode(.alwaysOriginal)
            let label = row.arrangedSubviews.last as? UILabel
            label?.text = text
            label?.textColor = isValid ? Palette.blue : (showsError ? Palette.error : Palette.placeholder)
        }
    }

    func clearInlineError(for field: UITextField) {
        fieldErrorRows[ObjectIdentifier(field)]?.isHidden = true
        field.layer.borderColor = (field.isFirstResponder ? Palette.focus : Palette.line).cgColor
        field.layer.borderWidth = field.isFirstResponder ? 1.5 : 1
    }

    var passwordRequirementsMet: Bool {
        let value = passwordField.text ?? ""
        return value.count >= 8
            && value.rangeOfCharacter(from: .letters) != nil
            && value.rangeOfCharacter(from: .decimalDigits) != nil
            && value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
    }

}
