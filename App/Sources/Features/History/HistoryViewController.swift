import UIKit

@MainActor
final class HistoryViewController: AppPageViewController, UITextFieldDelegate {
    private struct Conversation {
        let title: String
        let time: String
        let olderThanWeek: Bool
    }

    private let conversations = [
        Conversation(title: "기숙사 하루 일과가 어떻게 돼?", time: "오늘 · 선배 답변 2개", olderThanWeek: false),
        Conversation(title: "전공 선택은 어떻게 하는 게 좋아?", time: "어제 · 선배 답변 3개", olderThanWeek: false),
        Conversation(title: "동아리는 언제 정해?", time: "지난주 · 선배 답변 1개", olderThanWeek: true),
        Conversation(title: "입학하려면 뭘 준비해야 해?", time: "10월 28일 · 선배 답변 2개", olderThanWeek: true),
        Conversation(title: "과랑 전공이랑 뭐가 달라?", time: "10월 21일 · 선배 답변 1개", olderThanWeek: true),
        Conversation(title: "후배한테 해주고 싶은 조언 있어?", time: "10월 18일 · 선배 답변 2개", olderThanWeek: true)
    ]

    private let searchField = UITextField()
    private let periodControl = UISegmentedControl(items: ["지난 7일", "이전"])
    private let resultsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "기록"
        addHeading("지난 대화", subtitle: "이전 대화를 이어서 볼 수 있어요")

        searchField.placeholder = "지난 대화 검색"
        searchField.borderStyle = .roundedRect
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.delegate = self
        contentStack.addArrangedSubview(searchField)

        periodControl.selectedSegmentIndex = 0
        periodControl.addAction(UIAction { [weak self] _ in self?.renderConversations() }, for: .valueChanged)
        contentStack.addArrangedSubview(periodControl)

        resultsStack.axis = .vertical
        resultsStack.spacing = 10
        contentStack.addArrangedSubview(resultsStack)
        renderConversations()

        contentStack.addArrangedSubview(AppStyle.button("새 대화 시작", primary: true) { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        })
    }

    private func renderConversations() {
        resultsStack.arrangedSubviews.forEach { view in
            resultsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let isOlderSelected = periodControl.selectedSegmentIndex == 1
        let filtered = conversations.filter {
            $0.olderThanWeek == isOlderSelected && (query.isEmpty || $0.title.lowercased().contains(query))
        }
        guard !filtered.isEmpty else {
            resultsStack.addArrangedSubview(AppStyle.label("대화 기록이 없어요", size: 14, color: AppStyle.muted))
            return
        }
        filtered.forEach { conversation in
            addConversationRow(conversation)
        }
    }

    private func addConversationRow(_ conversation: Conversation) {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = AppStyle.line.cgColor
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 2
        var config = UIButton.Configuration.plain()
        config.title = conversation.title
        config.subtitle = conversation.time
        config.image = UIImage(systemName: "bubble.left.and.bubble.right")
        config.imagePlacement = .leading
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        config.baseForegroundColor = AppStyle.ink
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in
            self?.push(ChatConversationViewController(question: conversation.title))
        }, for: .touchUpInside)
        resultsStack.addArrangedSubview(button)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.async { [weak self] in self?.renderConversations() }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        renderConversations()
        view.endEditing(true)
        return true
    }
}
