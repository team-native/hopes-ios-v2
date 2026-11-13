import Foundation

@MainActor
final class UserProfileStore {
    static let shared = UserProfileStore()

    private let defaults = UserDefaults.standard
    private init() {}

    var name: String { defaults.string(forKey: "profile.name") ?? "임서하" }
    var department: String { defaults.string(forKey: "profile.department") ?? "인공지능소프트웨어과" }
    var email: String { defaults.string(forKey: "profile.email") ?? "s26055@gsm.hs.kr" }
    var generation: String { defaults.string(forKey: "profile.generation") ?? "10기" }
    var introduction: String { defaults.string(forKey: "profile.introduction") ?? "" }

    var hasPendingProfileSaveToast: Bool { defaults.bool(forKey: "profile.saveToastPending") }

    func consumeProfileSaveToast() -> Bool {
        let shouldShow = hasPendingProfileSaveToast
        defaults.set(false, forKey: "profile.saveToastPending")
        return shouldShow
    }

    func markProfileSaved() {
        defaults.set(true, forKey: "profile.saveToastPending")
    }

    func update(name: String, department: String, email: String, generation: String? = nil, introduction: String? = nil) {
        defaults.set(name, forKey: "profile.name")
        defaults.set(department, forKey: "profile.department")
        defaults.set(email, forKey: "profile.email")
        if let generation { defaults.set(generation, forKey: "profile.generation") }
        if let introduction { defaults.set(introduction, forKey: "profile.introduction") }
    }

    func isRegistered(email: String) -> Bool {
        registeredEmails.contains(email.lowercased())
    }

    func markRegistered(email: String) {
        var emails = registeredEmails
        emails.insert(email.lowercased())
        defaults.set(Array(emails).sorted(), forKey: "auth.registeredEmails")
    }

    private var registeredEmails: Set<String> {
        Set(defaults.stringArray(forKey: "auth.registeredEmails") ?? [])
    }
}
