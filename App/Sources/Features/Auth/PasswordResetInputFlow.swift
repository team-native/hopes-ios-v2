import UIKit

@MainActor
extension PasswordResetViewController {
    func setActionButtonInline(_ inline: Bool) {
        let isInDesiredContainer = inline
            ? actionButton.superview === contentStack
            : actionButton.superview === view
        guard !isInDesiredContainer || isActionButtonInline != inline else { return }

        if inline {
            NSLayoutConstraint.deactivate(actionButtonConstraints)
            actionButton.removeFromSuperview()
            contentStack.addArrangedSubview(actionButton)
        } else {
            if actionButton.superview === contentStack {
                contentStack.removeArrangedSubview(actionButton)
                actionButton.removeFromSuperview()
            }
            if actionButton.superview !== view {
                view.addSubview(actionButton)
                NSLayoutConstraint.activate(actionButtonConstraints)
            }
        }
        isActionButtonInline = inline
    }

    func updateActionButton() {
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
            enabled = true
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

    func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self,
                      let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                let local = self.view.convert(frame, from: nil)
                let overlap = max(0, self.view.bounds.maxY - local.minY)
                self.keyboardIsVisible = overlap > 1
                self.scrollView.contentInset.bottom = overlap + 64
                self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
                let inline = self.keyboardIsVisible && (self.step == .email || self.step == .verification)
                self.setActionButtonInline(inline)
                self.actionButton.transform = overlap > 0 && !inline
                    ? CGAffineTransform(translationX: 0, y: -overlap)
                    : .identity
            }
        })
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil,
            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.keyboardIsVisible = false
                self.setActionButtonInline(false)
                self.scrollView.contentInset.bottom = 0
                self.scrollView.verticalScrollIndicatorInsets.bottom = 0
                self.actionButton.transform = .identity
            }
        })
    }

    func startCountdown() {
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

    @objc func goBack() {
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

    @objc func performPrimaryAction() {
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
            requestResetCode()
        case .verification:
            guard (codeField.text ?? "").count == 6, countdown > 0 else {
                codeError = countdown > 0 ? "인증번호 6자리를 입력해 주세요." : "인증 시간이 지났어요. 인증번호를 다시 받아 주세요."
                render()
                return
            }
            step = .newPassword
            codeError = nil
            render()
        case .newPassword:
            passwordError = passwordRequirementsMet ? nil : "비밀번호 조건을 모두 맞춰 주세요."
            confirmError = newPasswordField.text == confirmPasswordField.text ? nil : "비밀번호가 일치하지 않아요."
            guard passwordError == nil, confirmError == nil else {
                render()
                return
            }
            submitNewPassword()
        case .complete:
            navigationController?.popToRootViewController(animated: true)
        }
    }

    @objc func codeChanged() {
        let digits = String((codeField.text ?? "").filter(\.isNumber).prefix(6))
        if codeField.text != digits { codeField.text = digits }
        let labels = codeDigits.arrangedSubviews.compactMap { $0.subviews.first as? UILabel }
        for index in labels.indices { labels[index].text = character(at: index) }
        updateCodeDigitFocus()
        if codeError != nil {
            codeError = nil
            render()
            DispatchQueue.main.async { [weak self] in self?.codeField.becomeFirstResponder() }
        }
        updateActionButton()
    }

    func updateCodeDigitFocus() {
        let activeIndex = (codeField.text ?? "").count
        for (index, box) in codeDigits.arrangedSubviews.enumerated() {
            let isActive = codeError == nil && codeField.isFirstResponder && index == activeIndex
            box.layer.borderColor = (codeError != nil ? Palette.error : (isActive ? Palette.focus : Palette.fieldLine))
                .cgColor
            box.layer.borderWidth = codeError != nil || isActive ? 1.5 : 1
        }
    }

    func updatePasswordRequirementRows() {
        let value = newPasswordField.text ?? ""
        let states: [(String, Bool)] = [
            ("8자 이상", value.count >= 8),
            (
                "영문과 숫자 포함",
                value.rangeOfCharacter(from: .letters) != nil &&
                    value.rangeOfCharacter(from: .decimalDigits) != nil
            ),
            ("특수문자 포함", value.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil)
        ]
        guard let rows = passwordRequirementsStack?.arrangedSubviews as? [UIStackView] else { return }
        for (row, state) in zip(rows, states) {
            (row.arrangedSubviews.first as? UIImageView)?.image = UIImage(
                named: state.1 ? "SignupRuleCheck" : "SignupRuleCheckMuted"
            )
            let label = row.arrangedSubviews.last as? UILabel
            label?.text = state.0
            label?.textColor = state.1 ? Palette.blue : Palette.muted
        }
    }

    func clearInlineError(for field: UITextField) {
        fieldErrorRows[ObjectIdentifier(field)]?.isHidden = true
        field.layer.borderColor = (field.isFirstResponder ? Palette.focus : Palette.fieldLine).cgColor
        field.layer.borderWidth = field.isFirstResponder ? 1.5 : 1
    }

    @objc func passwordChanged() {
        let password = newPasswordField.text ?? ""
        let confirmation = confirmPasswordField.text ?? ""
        if passwordError != nil, password.isEmpty || passwordRequirementsMet {
            passwordError = nil
            clearInlineError(for: newPasswordField)
        }
        if confirmError != nil, confirmation.isEmpty || password == confirmation {
            confirmError = nil
            clearInlineError(for: confirmPasswordField)
        }
        updatePasswordRequirementRows()
        updateActionButton()
    }

    @objc func changeEmail() {
        step = .email
        codeError = nil
        countdownTimer?.invalidate()
        render()
    }

    @objc func resendCode() {
        requestResetCode()
    }

    func requestResetCode() {
        runRequest {
            try await AuthAPI.requestPasswordResetCode(email: self.email)
            self.emailError = nil
            self.codeError = nil
            self.codeField.text = ""
            self.step = .verification
            self.render()
            self.startCountdown()
        } onError: { error in
            if self.step == .verification {
                self.codeError = error.message
            } else {
                self.emailError = error.message
                self.step = .email
            }
            self.render()
        }
    }

    func submitNewPassword() {
        let password = newPasswordField.text ?? ""
        let code = codeField.text ?? ""
        runRequest {
            try await AuthAPI.resetPassword(email: self.email, code: code, newPassword: password)
            self.countdownTimer?.invalidate()
            self.step = .complete
            self.render()
        } onError: { error in
            switch error.status {
            case 404:
                self.emailError = "가입되지 않은 이메일이에요. 회원가입을 진행해 주세요."
                self.step = .unregistered
            case 400 where error.message.contains("인증번호"):
                self.codeError = "인증번호가 맞지 않아요. 다시 확인해 주세요."
                self.step = .verification
            default:
                self.passwordError = error.message
            }
            self.render()
        }
    }

    func runRequest(
        _ operation: @escaping @MainActor () async throws -> Void,
        onError: @escaping @MainActor (APIError) -> Void
    ) {
        actionButton.isEnabled = false
        actionButton.backgroundColor = Palette.blue.withAlphaComponent(0.68)
        Task { @MainActor in
            do {
                try await operation()
            } catch {
                onError(error as? APIError ?? .network)
            }
            self.updateActionButton()
        }
    }

}
