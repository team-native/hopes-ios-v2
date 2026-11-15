import UIKit

@MainActor
extension SignupViewController {
    @objc func emailDidChange() {
        guard emailError != nil else { return }
        emailError = nil
        emailErrorRow?.isHidden = true
        emailField.layer.borderColor = Palette.focus.cgColor
        emailField.layer.borderWidth = 1.5
        updateActionButton()
    }

    @objc func codeChanged() {
        let digits = String((codeField.text ?? "").filter(\.isNumber).prefix(6))
        if codeField.text != digits { codeField.text = digits }
        let labels = codeDigits.arrangedSubviews.compactMap { $0.subviews.first as? UILabel }
        for index in labels.indices { labels[index].text = character(at: index) }
        updateVerificationDigitAppearance()
        if codeError != nil {
            codeError = nil
            render()
            DispatchQueue.main.async { [weak self] in self?.codeField.becomeFirstResponder() }
        }
        updateActionButton()
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
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
        if textField === codeField {
            updateVerificationDigitAppearance()
            return
        }
        let hasError = (textField === emailField && emailError != nil)
            || (textField === passwordField && passwordError != nil)
            || (textField === confirmField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.focus).cgColor
        textField.layer.borderWidth = 1.5
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === codeField {
            updateVerificationDigitAppearance()
            return
        }
        let hasError = (textField === emailField && emailError != nil)
            || (textField === passwordField && passwordError != nil)
            || (textField === confirmField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.line).cgColor
        textField.layer.borderWidth = hasError ? 1.5 : 1
    }
}
