import Foundation

enum AuthPasswordPolicy {
    static let maxLength = 15

    static func allowsChange(in text: String?, range: NSRange, replacement: String) -> Bool {
        let current = text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        return current.replacingCharacters(in: swiftRange, with: replacement).count <= maxLength
    }
}
