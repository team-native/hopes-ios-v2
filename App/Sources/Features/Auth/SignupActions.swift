import UIKit

@MainActor
extension SignupViewController {
    func updateActionButton() {
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
            enabled = passwordRequirementsMet && passwordsMatch
        case .passwordReady:
            title = "다음"
            enabled = true
        case .profile:
            title = "가입 완료"
            enabled = generation != nil && termsAccepted && hasProfileName
        case .complete:
            title = "채팅 시작하기"
            enabled = true
        }
        actionButton.setTitle(title, for: .normal)
        actionButton.isEnabled = enabled
        actionButton.backgroundColor = enabled ? Palette.blue : Palette.blue.withAlphaComponent(0.38)
        actionButton.setTitleColor(.white, for: .normal)
    }

    private var passwordsMatch: Bool {
        passwordField.text == confirmField.text && !(confirmField.text ?? "").isEmpty
    }

    private var hasProfileName: Bool {
        !(nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil, queue: .main) { [weak self] note in
            guard let self,
                  let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let local = self.view.convert(frame, from: nil)
            let overlap = max(0, self.view.bounds.maxY - local.minY)
            self.scrollView.contentInset.bottom = overlap + 64
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
            self.actionButton.transform = overlap > 0 ? CGAffineTransform(translationX: 0, y: -overlap) : .identity
        })
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil,
            queue: .main) { [weak self] _ in
            self?.scrollView.contentInset.bottom = 0
            self?.scrollView.verticalScrollIndicatorInsets.bottom = 0
            self?.actionButton.transform = .identity
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
                    self.timerLabel.text = "인증번호 유효 시간  \(self.formattedCountdown)"
                }
            }
        }
    }

    func presentPicker(
        title: String,
        options: [String],
        selected: String?,
        completion: @escaping (String) -> Void
    ) {
        guard sheetView == nil else { return }
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        constrainOverlay(overlay)
        _ = makePickerSheet(in: overlay, title: title, options: options, selected: selected, completion: completion)
        sheetView = overlay
    }

    private func constrainOverlay(_ overlay: UIView) {
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makePickerSheet(
        in overlay: UIView,
        title: String,
        options: [String],
        selected: String?,
        completion: @escaping (String) -> Void
    ) -> UIView {
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
        configurePickerSheet(sheet: sheet, handle: handle, heading: heading, optionsStack: optionsStack)
        addPickerOptions(options, selected: selected, in: optionsStack, overlay: overlay, completion: completion)
        return sheet
    }

    private func configurePickerSheet(
        sheet: UIView,
        handle: UIView,
        heading: UILabel,
        optionsStack: UIStackView
    ) {
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
            optionsStack.bottomAnchor.constraint(lessThanOrEqualTo: sheet.safeAreaLayoutGuide.bottomAnchor,
                constant: -12)
        ])
    }

    private func addPickerOptions(
        _ options: [String],
        selected: String?,
        in optionsStack: UIStackView,
        overlay: UIView,
        completion: @escaping (String) -> Void
    ) {
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
    }

}

@MainActor
extension SignupViewController {
    @objc func goBack() {
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

    @objc func performPrimaryAction() {
        view.endEditing(true)
        switch step {
        case .email:
            submitEmail()
        case .verification:
            verifyCode()
        case .verified:
            step = .password
            render()
        case .password:
            validatePassword()
        case .passwordReady:
            step = .profile
            render()
        case .profile:
            completeProfile()
        case .complete:
            navigationController?.setViewControllers([OnboardingViewController()], animated: true)
        }
    }

    private func submitEmail() {
        email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.lowercased().hasSuffix("@gsm.hs.kr") else {
            emailError = "학교 이메일(@gsm.hs.kr)만 사용할 수 있어요."
            render()
            return
        }
        guard !UserProfileStore.shared.isRegistered(email: email) else {
            showAlreadyRegisteredNotice()
            return
        }
        emailError = nil
        step = .verification
        codeField.text = ""
        codeError = nil
        render()
        startCountdown()
    }

    private func verifyCode() {
        guard (codeField.text ?? "").count == 6, countdown > 0 else {
            codeError = countdown == 0
                ? "인증 시간이 지났어요. 인증번호를 다시 받아 주세요."
                : "인증번호 6자리를 입력해 주세요."
            render()
            return
        }
        step = .verified
        codeError = nil
        countdownTimer?.invalidate()
        render()
    }

    private func validatePassword() {
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
    }

    private func completeProfile() {
        guard generation != nil else {
            generationError = true
            render()
            return
        }
        guard termsAccepted else { return }
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        UserProfileStore.shared.update(
            name: name,
            department: selectedDepartment,
            email: email,
            generation: generation
        )
        UserProfileStore.shared.markRegistered(email: email)
        step = .complete
        countdownTimer?.invalidate()
        render()
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
        let password = passwordField.text ?? ""
        let confirmation = confirmField.text ?? ""
        passwordError = password.isEmpty || passwordRequirementsMet ? nil : "비밀번호 조건을 모두 맞춰 주세요."
        confirmError = confirmation.isEmpty || confirmation == password ? nil : "비밀번호가 일치하지 않아요."
        let responder = [passwordField, confirmField].first(where: \.isFirstResponder)
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

    @objc func showDepartmentPicker() {
        presentPicker(title: "과 선택", options: ["소프트웨어과", "인공지능과", "게임과", "스마트IoT과"],
            selected: selectedDepartment) { [weak self] value in
            self?.selectedDepartment = value
        }
    }

    @objc func showGenerationPicker() {
        presentPicker(title: "기수 선택", options: ["8기", "9기", "10기", "11기"], selected: generation) { [weak self] value in
            self?.generation = value
            self?.generationError = false
        }
    }

    @objc func dismissPicker() {
        sheetView?.removeFromSuperview()
        sheetView = nil
    }

    @objc func toggleTerms() {
        termsAccepted.toggle()
        termsButton.configuration = checkboxConfiguration()
        updateActionButton()
    }

    @objc func profileNameChanged() {
        updateActionButton()
    }

    func showAlreadyRegisteredNotice() {
        let alert = UIAlertController(title: "이미 가입된 이메일이에요", message: "이미 가입된 계정이 있어요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

}
