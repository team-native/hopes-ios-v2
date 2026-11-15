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
        let actionContainer = UIStackView(arrangedSubviews: [actionButton])
        actionContainer.axis = .vertical
        actionContainer.isLayoutMarginsRelativeArrangement = true
        actionContainer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(actionContainer)
        let actionBottomSpacer = UIView()
        actionBottomSpacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        contentStack.addArrangedSubview(actionBottomSpacer)
        if step == .complete {
            let minimumHeight = contentStack.heightAnchor.constraint(
                greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor
            )
            minimumHeight.isActive = true
        }
        updateActionButton()
        backButton.isHidden = step == .complete
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
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"])

        addVerificationEmailRow()

        addVerificationCodeDigits()

        addVerificationTimerRow()
    }

    private func addVerificationEmailRow() {
        let emailSection = UIStackView()
        emailSection.axis = .vertical
        emailSection.spacing = 6
        emailSection.isLayoutMarginsRelativeArrangement = true
        emailSection.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        emailSection.addArrangedSubview(makeLabel("학교 이메일", size: 14, weight: .medium, color: Palette.muted))
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
        codeDigits.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let codeSection = UIStackView(arrangedSubviews: [
            makeLabel("인증번호 6자리", size: 14, weight: .medium, color: Palette.muted),
            codeDigits
        ])
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
            if codeError != nil {
                digitBox.layer.borderColor = Palette.error.cgColor
                digitBox.layer.borderWidth = 1
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
        timerLabel.accessibilityLabel = "인증번호 유효 시간 \(formattedCountdown)"
        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.tintColor = Palette.blue
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
        resend.setTitleColor(Palette.blue, for: .normal)
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
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"])

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
        verified.isLayoutMarginsRelativeArrangement = true
        verified.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(verified)
    }

    func renderPasswordStep() {
        let isReady = step == .passwordReady
        passwordField.isUserInteractionEnabled = !isReady
        confirmField.isUserInteractionEnabled = !isReady
        addStepper(current: 1)
        addHeading(lines: ["로그인에 쓸", "비밀번호를 만들어 주세요"])
        addField(label: "비밀번호", field: passwordField, error: passwordError, showsVisibility: true)
        addSpacer(14)

        let requirements = UIStackView()
        requirements.axis = .vertical
        requirements.spacing = 6
        let value = passwordField.text ?? ""
        let requirementsList: [(String, Bool)] = [
            ("8자 이상", value.count >= 8),
            (
                "영문과 숫자 포함",
                value.rangeOfCharacter(from: .letters) != nil &&
                    value.rangeOfCharacter(from: .decimalDigits) != nil
            ),
            ("특수문자 포함", value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil)
        ]
        requirementsList.forEach { text, isValid in
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 6
            let image = UIImageView(image: UIImage(systemName: "checkmark"))
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
    }

    func renderProfileStep() {
        addStepper(current: 2)
        addHeading(lines: ["선배에게 보여줄", "기본 정보를 알려주세요"], subtitle: "커뮤니티에는 이름 대신 기수만 표시돼요.", accentPrefix: "선배")
        addField(label: "이름", field: nameField)

        departmentButton.configuration = dropdownConfiguration(title: selectedDepartment, error: false)
        addLabeledControl(label: "과", control: departmentButton)

        generationButton.configuration = dropdownConfiguration(title: generation ?? "기수 선택", error: generationError)
        addLabeledControl(label: "기수", control: generationButton, error: generationError ? "기수를 선택해 주세요." : nil)

        termsButton.configuration = checkboxConfiguration()
        contentStack.addArrangedSubview(termsButton)
        termsButton.translatesAutoresizingMaskIntoConstraints = false
        termsButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        addSpacer(20)
    }

    func renderCompleteStep() {
        addSpacer(16)
        addFlexibleSpacer()
        addSpacer(16)

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        let checkContainer = UIView()
        checkContainer.backgroundColor = .white
        checkContainer.layer.borderColor = Palette.line.cgColor
        checkContainer.layer.borderWidth = 1
        checkContainer.layer.cornerRadius = 48
        checkContainer.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        checkContainer.layer.shadowOpacity = 0.09
        checkContainer.layer.shadowRadius = 14
        checkContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        checkContainer.widthAnchor.constraint(equalToConstant: 96).isActive = true
        checkContainer.heightAnchor.constraint(equalToConstant: 96).isActive = true
        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = Palette.blue
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        checkContainer.addSubview(check)
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: checkContainer.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: checkContainer.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 44),
            check.heightAnchor.constraint(equalToConstant: 44)
        ])
        content.addArrangedSubview(checkContainer)
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? UserProfileStore.shared.name
        content.addArrangedSubview(makeLabel("\(name)님, 가입이 끝났어요", size: 22, weight: .bold, color: Palette.ink,
            alignment: .center))
        let department = UserProfileStore.shared.department
        content.addArrangedSubview(makeLabel("\(department) · \(generation ?? "10기")로 가입했어요.\n이제 선배에게 무엇이든 물어보세요.",
            size: 14, weight: .medium, color: Palette.muted, alignment: .center))
        contentStack.addArrangedSubview(content)

        addSpacer(16)
        addFlexibleSpacer()
        addSpacer(16)
    }

    private func addFlexibleSpacer() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    func character(at index: Int) -> String {
        let digits = Array(codeField.text ?? "")
        return index < digits.count ? String(digits[index]) : ""
    }

    var formattedCountdown: String {
        String(format: "%02d:%02d", countdown / 60, countdown % 60)
    }

    var passwordRequirementsMet: Bool {
        let value = passwordField.text ?? ""
        return value.count >= 8
            && value.rangeOfCharacter(from: .letters) != nil
            && value.rangeOfCharacter(from: .decimalDigits) != nil
            && value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
    }

}
