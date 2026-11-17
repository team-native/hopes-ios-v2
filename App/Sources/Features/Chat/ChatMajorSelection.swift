import Foundation

enum ChatMajorSelection {
    static let listKey = "chat.selectedMajors"
    static let primaryKey = "chat.selectedMajor"

    static func load(defaults: UserDefaults = .standard, fallback: [String] = ["Frontend"]) -> [String] {
        if let list = defaults.stringArray(forKey: listKey) { return list }
        guard let stored = defaults.string(forKey: primaryKey) else { return fallback }
        return stored.isEmpty ? [] : [stored]
    }

    static func save(_ majors: [String], defaults: UserDefaults = .standard) {
        defaults.set(majors, forKey: listKey)
        defaults.set(majors.first ?? "", forKey: primaryKey)
    }

    static func displayName(_ majors: [String]) -> String? {
        switch majors.count {
        case 0: nil
        case 1, 2: majors.joined(separator: ", ")
        default: "\(majors[0]) 외 \(majors.count - 1)"
        }
    }

    static func studyQuestion(for major: String?) -> String {
        guard let major, major != "기타" else { return "전공 공부는 뭐부터 하면 좋아?" }
        let particle = ["Design"].contains(major) ? "은" : "는"
        return "\(major)\(particle) 뭐부터 공부하면 좋아?"
    }
}

@MainActor
extension ChatHomeViewController {
    static func defaultQuestionSets(major: String?) -> [[(String, String)]] { [
        [
            ("chat-question-bed-icon", "기숙사 하루 일과가 어떻게 돼?"),
            ("chat-question-file-icon", "입학하려면 뭘 준비해야 해?"),
            ("chat-question-code-icon", ChatMajorSelection.studyQuestion(for: major)),
            ("chat-question-heart-icon", "후배한테 해주고 싶은 조언 있어?")
        ],
        [
            ("chat-question-code-icon", "처음 만드는 프로젝트는 어떤 게 좋아?"),
            ("chat-question-bed-icon", "기숙사 생활에 필요한 준비물이 뭐야?"),
            ("chat-question-file-icon", "입학 전에 공부하면 좋은 과목이 있어?"),
            ("chat-question-heart-icon", "학교생활에서 가장 기억에 남는 일은 뭐야?")
        ]
    ] }
}
