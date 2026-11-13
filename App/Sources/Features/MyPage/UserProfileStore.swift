import Foundation

@MainActor
final class UserProfileStore {
    static let shared = UserProfileStore()

    private let defaults = UserDefaults.standard
    private init() {}

    var name: String { defaults.string(forKey: "profile.name") ?? "임서하" }
    var department: String { defaults.string(forKey: "profile.department") ?? "인공지능과" }
    var email: String { defaults.string(forKey: "profile.email") ?? "s26055@gsm.hs.kr" }

    func update(name: String, department: String, email: String) {
        defaults.set(name, forKey: "profile.name")
        defaults.set(department, forKey: "profile.department")
        defaults.set(email, forKey: "profile.email")
    }
}
