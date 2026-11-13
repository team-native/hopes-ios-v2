import UIKit

@MainActor
final class NotificationsViewController: AppPageViewController {
    private struct NotificationItem {
        let title: String
        let detail: String
        let category: String
        let question: String?
        var isRead: Bool
    }

    private var items = [
        NotificationItem(title: "내 질문에 새 답변이 달렸어요", detail: "기숙사 하루 일과가 어떻게 돼? · 10분 전", category: "답변", question: "기숙사 하루 일과가 어떻게 돼?", isRead: false),
        NotificationItem(title: "게시글에 댓글이 달렸어요", detail: "기숙사 와이파이 다들 잘 돼? · 1시간 전", category: "답변", question: "기숙사 와이파이 다들 잘 돼?", isRead: false),
        NotificationItem(title: "이번 주 학교 일정 안내", detail: "학교 공지 · 어제", category: "공지", question: nil, isRead: true)
    ]

    private let categoryControl = UISegmentedControl(items: ["전체", "답변", "공지"])
    private let itemsStack = UIStackView()
    private var selectedCategory = "전체"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알림"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "모두 읽음", style: .plain, target: self, action: #selector(markAllRead))
        addHeading("알림", subtitle: "새 답변과 학교 소식을 확인해요")

        categoryControl.selectedSegmentIndex = 0
        categoryControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.selectedCategory = ["전체", "답변", "공지"][self.categoryControl.selectedSegmentIndex]
            self.renderItems()
        }, for: .valueChanged)
        contentStack.addArrangedSubview(categoryControl)

        itemsStack.axis = .vertical
        itemsStack.spacing = 10
        contentStack.addArrangedSubview(itemsStack)
        renderItems()
    }

    private func renderItems() {
        itemsStack.arrangedSubviews.forEach { view in
            itemsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let visible = items.filter { selectedCategory == "전체" || $0.category == selectedCategory }
        guard !visible.isEmpty else {
            itemsStack.addArrangedSubview(AppStyle.label("새로운 알림이 없어요", size: 14, color: AppStyle.muted))
            return
        }
        visible.enumerated().forEach { index, item in
            addRow(item.title, subtitle: "\(item.isRead ? "" : "●  ")\(item.detail)", symbol: item.category == "공지" ? "megaphone" : "bubble.left") { [weak self] in
                guard let self else { return }
                let actualIndex = self.items.firstIndex { $0.title == item.title && $0.detail == item.detail } ?? index
                self.items[actualIndex].isRead = true
                if let question = item.question {
                    self.push(ChatConversationViewController(question: question))
                } else {
                    self.showMessage(item.title)
                }
                self.renderItems()
            }
        }
    }

    @objc private func markAllRead() {
        items = items.map { item in
            var updated = item
            updated.isRead = true
            return updated
        }
        renderItems()
    }
}
