import UIKit

@MainActor
extension SignupViewController {
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
        let hasError = (textField === emailField && emailError != nil)
            || (textField === passwordField && passwordError != nil)
            || (textField === confirmField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.blue).cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let hasError = (textField === emailField && emailError != nil)
            || (textField === passwordField && passwordError != nil)
            || (textField === confirmField && confirmError != nil)
        textField.layer.borderColor = (hasError ? Palette.error : Palette.line).cgColor
    }
}
