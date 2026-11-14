import UIKit

@MainActor
extension SignupViewController {
    func render() {
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        renderCurrentStep()
        updateActionButton()
        backButton.isHidden = step == .complete
        scrollView.setContentOffset(.zero, animated: false)
        focusFieldForCurrentStep()
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
        addHeading(lines: ["학교 이메일로", "인증해 주세요"])
        addField(label: "학교 이메일", field: emailField, error: emailError)
        addSpacer(30)
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
    }

    private func addVerificationCodeDigits() {
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
    }

    private func addVerificationTimerRow() {
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

}

@MainActor
extension SignupViewController {
    func renderVerifiedStep() {
        codeField.isUserInteractionEnabled = false
        addStepper(current: 0)
        addHeading(lines: ["메일로 받은", "인증번호를 입력해 주세요"])

        addVerifiedEmailRow()

        addVerifiedCodeDigits()

        addVerifiedConfirmation()
    }

    private func addVerifiedEmailRow() {
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
    }

    private func addVerifiedCodeDigits() {
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
    }

    private func addVerifiedConfirmation() {
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

    func renderPasswordStep() {
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

    func renderProfileStep() {
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

    func renderCompleteStep() {
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
        content.addArrangedSubview(makeLabel("\(name)님, 가입이 끝났어요", size: 22, weight: .bold, color: Palette.ink,
            alignment: .center))
        let department = UserProfileStore.shared.department
        content.addArrangedSubview(makeLabel("\(department) · \(generation ?? "10기")로 가입했어요.\n이제 선배에게 무엇이든 물어보세요.",
            size: 14, color: Palette.muted, alignment: .center))
        contentStack.addArrangedSubview(content)

        let bottomSpace = UIView()
        contentStack.addArrangedSubview(bottomSpace)
        bottomSpace.heightAnchor.constraint(equalToConstant: 160).isActive = true
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
