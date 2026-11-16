import UIKit

@MainActor
extension SignupViewController {
    func submitEmail() {
        email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidSchoolEmail else {
            emailError = "학교 이메일(@gsm.hs.kr)만 사용할 수 있어요."
            render(focusField: false)
            return
        }
        runRequest {
            try await AuthAPI.requestSignupCode(email: self.email)
            self.emailError = nil
            self.step = .verification
            self.codeField.text = ""
            self.codeError = nil
            self.render()
            self.startCountdown()
        } onError: { error in
            self.emailError = error.message
            self.render(focusField: false)
        }
    }

    func verifyCode() {
        guard (codeField.text ?? "").count == 6, countdown > 0 else {
            codeError = countdown == 0
                ? "인증 시간이 지났어요. 인증번호를 다시 받아 주세요."
                : "인증번호 6자리를 입력해 주세요."
            render(focusField: false)
            return
        }
        let code = codeField.text ?? ""
        runRequest {
            try await AuthAPI.confirmSignupCode(email: self.email, code: code)
            self.step = .verified
            self.codeError = nil
            self.countdownTimer?.invalidate()
            self.render()
        } onError: { error in
            self.codeError = error.status == 400 ? "인증번호가 맞지 않아요. 다시 확인해 주세요." : error.message
            self.render(focusField: false)
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

    func showRequestError(_ error: APIError) {
        let alert = UIAlertController(title: nil, message: error.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func showAlreadyRegisteredNotice() {
        let alert = UIAlertController(title: "이미 가입된 이메일이에요", message: "이미 가입된 계정이 있어요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self, self.step != .email else { return }
            self.step = .email
            self.countdownTimer?.invalidate()
            self.render()
        })
        present(alert, animated: true)
    }

    @objc func resendCode() {
        runRequest {
            try await AuthAPI.requestSignupCode(email: self.email)
            self.codeField.text = ""
            self.codeError = nil
            self.render()
            self.startCountdown()
        } onError: { error in
            self.codeError = error.message
            self.render(focusField: false)
        }
    }
}
