import UIKit

@MainActor
extension HistoryViewController {
    func loadConversations() {
        guard AccessTokenStore.shared.hasToken else { return }
        Task { [weak self] in
            guard let list = try? await ChatAPI.list(), let self else { return }
            self.conversations = list.chatList.map(Self.conversation(from:))
            self.buildContent()
        }
    }

    static func conversation(from summary: ChatSummaryDTO) -> Conversation {
        let date = ChatAPI.date(from: summary.updatedAt) ?? Date()
        let days = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: date), to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        let time: String
        switch days {
        case ..<1: time = "오늘"
        case 1: time = "어제"
        case 2..<7: time = "\(days)일 전"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일"
            time = formatter.string(from: date)
        }
        return Conversation(
            id: summary.id,
            title: summary.title,
            time: time,
            department: UserProfileStore.shared.department,
            olderThanWeek: days >= 7
        )
    }

    func highlightedTitle(_ title: String, query: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 24
        paragraph.maximumLineHeight = 24
        let result = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: AppStyle.ink,
                .paragraphStyle: paragraph
            ]
        )
        guard !query.isEmpty, let range = title.range(of: query, options: [.caseInsensitive,
            .diacriticInsensitive]) else { return result }
        let nsRange = NSRange(range, in: title)
        result.addAttributes([.foregroundColor: AppStyle.blue, .font: UIFont.systemFont(ofSize: 15,
            weight: .medium)], range: nsRange)
        return result
    }

    func openConversation(_ conversation: Conversation) {
        if let id = conversation.id {
            push(ChatConversationViewController(conversationID: id))
        } else {
            push(ChatConversationViewController(question: conversation.title))
        }
    }
}
