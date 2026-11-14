import UIKit

@MainActor
extension PasswordResetViewController {
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

    func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self,
                      let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                let local = self.view.convert(frame, from: nil)
                let overlap = max(0, self.view.bounds.maxY - local.minY)
                self.scrollView.contentInset.bottom = overlap + 64
                self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
                self.actionButton.transform = overlap > 0 ? CGAffineTransform(translationX: 0, y: -overlap) : .identity
            }
        })
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil,
            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scrollView.contentInset.bottom = 0
                self?.scrollView.verticalScrollIndicatorInsets.bottom = 0
                self?.actionButton.transform = .identity
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

    @objc func codeChanged() {
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

    @objc func passwordChanged() {
        let responder = [newPasswordField, confirmPasswordField].first(where: \.isFirstResponder)
        let password = newPasswordField.text ?? ""
        let confirmation = confirmPasswordField.text ?? ""
        passwordError = password.isEmpty || passwordRequirementsMet ? nil : "비밀번호 조건을 모두 맞춰 주세요."
        confirmError = confirmation.isEmpty || password == confirmation ? nil : "비밀번호가 일치하지 않아요."
        render()
        DispatchQueue.main.async { responder?.becomeFirstResponder() }
    }

    @objc func changeEmail() {
        step = .email
        codeError = nil
        countdownTimer?.invalidate()
        render()
    }

    @objc func resendCode() {
        codeField.text = ""
        codeError = nil
        render()
        startCountdown()
    }

}
