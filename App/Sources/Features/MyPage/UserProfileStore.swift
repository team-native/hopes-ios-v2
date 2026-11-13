import Foundation

@MainActor
final class UserProfileStore {
    static let shared = UserProfileStore()

    private let defaults = UserDefaults.standard
    private init() {}

    var name: String { defaults.string(forKey: "profile.name") ?? "임서하" }
    var department: String { defaults.string(forKey: "profile.department") ?? "인공지능과" }
    var email: String { defaults.string(forKey: "profile.email") ?? "s26055@gsm.hs.kr" }
    var introduction: String { defaults.string(forKey: "profile.introduction") ?? "프론트엔드에 관심 많은 10기 학생이에요.\nReact 공부 중" }

    var hasPendingProfileSaveToast: Bool { defaults.bool(forKey: "profile.saveToastPending") }

    func consumeProfileSaveToast() -> Bool {
        let shouldShow = hasPendingProfileSaveToast
        defaults.set(false, forKey: "profile.saveToastPending")
        return shouldShow
    }

    func markProfileSaved() {
        defaults.set(true, forKey: "profile.saveToastPending")
    }

    func update(name: String, department: String, email: String, introduction: String? = nil) {
        defaults.set(name, forKey: "profile.name")
        defaults.set(department, forKey: "profile.department")
        defaults.set(email, forKey: "profile.email")
        if let introduction { defaults.set(introduction, forKey: "profile.introduction") }
    }
}
