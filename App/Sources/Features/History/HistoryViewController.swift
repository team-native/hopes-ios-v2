import UIKit

@MainActor
final class HistoryViewController: AppPageViewController, UITextFieldDelegate {
    private struct Conversation {
        let title: String
        let time: String
        let department: String
        let olderThanWeek: Bool
    }

    private let conversations = [
        Conversation(title: "기숙사 하루 일과가 어떻게 돼?", time: "어제", department: "소프트웨어개발과", olderThanWeek: false),
        Conversation(title: "기숙사 방 배정은 어떻게 돼?", time: "3일 전", department: "소프트웨어개발과", olderThanWeek: false),
        Conversation(title: "전공 선택은 어떻게 하는 게 좋아?", time: "어제", department: "소프트웨어개발과", olderThanWeek: false),
        Conversation(title: "동아리는 언제 정해?", time: "지난주", department: "소프트웨어개발과", olderThanWeek: true),
        Conversation(title: "입학하려면 뭘 준비해야 해?", time: "10월 28일", department: "소프트웨어개발과", olderThanWeek: true),
        Conversation(title: "과랑 전공이랑 뭐가 달라?", time: "10월 21일", department: "소프트웨어개발과", olderThanWeek: true),
        Conversation(title: "후배한테 해주고 싶은 조언 있어?", time: "10월 18일", department: "소프트웨어개발과", olderThanWeek: true)
    ]

    private let searchField = UITextField()
    private let periodControl = UISegmentedControl(items: ["지난 7일", "이전"])
    private let resultsCountLabel = AppStyle.label("", size: 14, color: AppStyle.muted)
    private let resultsStack = UIStackView()
    private let clearSearchButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "기록"
        contentStack.spacing = 14
        addHeading("지난 대화", subtitle: "이전 대화를 이어서 볼 수 있어요.")
        addSearchField()

        periodControl.selectedSegmentIndex = 0
        periodControl.addAction(UIAction { [weak self] _ in self?.renderConversations() }, for: .valueChanged)
        contentStack.addArrangedSubview(periodControl)
        contentStack.addArrangedSubview(resultsCountLabel)

        resultsStack.axis = .vertical
        contentStack.addArrangedSubview(resultsStack)
        renderConversations()

        contentStack.addArrangedSubview(AppStyle.button("새 대화 시작", primary: true) { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        })
    }

    private func addSearchField() {
        let searchIcon = UIImageView(image: image(named: "history-search"))
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        searchIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        searchField.placeholder = "지난 대화 검색"
        searchField.borderStyle = .none
        searchField.font = .systemFont(ofSize: 15)
        searchField.textColor = AppStyle.ink
        searchField.returnKeyType = .search
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchTextDidChange), for: .editingChanged)

        clearSearchButton.setImage(image(named: "history-clear"), for: .normal)
        clearSearchButton.tintColor = AppStyle.muted
        clearSearchButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        clearSearchButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        clearSearchButton.isHidden = true
        clearSearchButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.searchField.text = ""
            self.renderConversations()
            self.searchField.becomeFirstResponder()
        }, for: .touchUpInside)

        let fieldRow = UIStackView(arrangedSubviews: [searchIcon, searchField, clearSearchButton])
        fieldRow.axis = .horizontal
        fieldRow.alignment = .center
        fieldRow.spacing = 10
        fieldRow.isLayoutMarginsRelativeArrangement = true
        fieldRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        fieldRow.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 24
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.66, green: 0.80, blue: 0.98, alpha: 1).cgColor
        container.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.10).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.addSubview(fieldRow)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 44),
            fieldRow.topAnchor.constraint(equalTo: container.topAnchor),
            fieldRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            fieldRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            fieldRow.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        contentStack.addArrangedSubview(container)
    }

    @objc private func searchTextDidChange() {
        renderConversations()
    }

    private func renderConversations() {
        resultsStack.arrangedSubviews.forEach { view in
            resultsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isSearching = !query.isEmpty
        clearSearchButton.isHidden = !isSearching
        periodControl.isHidden = isSearching

        let isOlderSelected = periodControl.selectedSegmentIndex == 1
        let filtered = conversations.filter { conversation in
            (isSearching || conversation.olderThanWeek == isOlderSelected)
                && (query.isEmpty || conversation.title.localizedCaseInsensitiveContains(query))
        }
        resultsCountLabel.text = isSearching ? "검색 결과 \(filtered.count)개" : "지난 대화 \(filtered.count)개"
        guard !filtered.isEmpty else {
            resultsStack.addArrangedSubview(AppStyle.label("대화 기록이 없어요", size: 14, color: AppStyle.muted))
            return
        }
        addConversationCard(filtered, query: query)
    }

    private func addConversationCard(_ conversations: [Conversation], query: String) {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.06).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 4),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4)
        ])

        for (index, conversation) in conversations.enumerated() {
            rows.addArrangedSubview(makeConversationRow(conversation, query: query))
            if index < conversations.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor(red: 0.90, green: 0.93, blue: 0.97, alpha: 1)
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                rows.addArrangedSubview(divider)
            }
        }
        resultsStack.addArrangedSubview(card)
    }

    private func makeConversationRow(_ conversation: Conversation, query: String) -> UIControl {
        let row = UIControl()
        row.addAction(UIAction { [weak self] _ in
            self?.push(ChatConversationViewController(question: conversation.title))
        }, for: .touchUpInside)

        let title = UILabel()
        title.attributedText = highlightedTitle(conversation.title, query: query)
        title.numberOfLines = 1
        let subtitle = AppStyle.label("\(conversation.time) · \(conversation.department)", size: 12, color: UIColor(red: 0.60, green: 0.65, blue: 0.73, alpha: 1))
        subtitle.numberOfLines = 1
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 4
        let chevron = UIImageView(image: image(named: "history-chevron"))
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 12).isActive = true
        let content = UIStackView(arrangedSubviews: [labels, chevron])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -16),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
        row.accessibilityLabel = "\(conversation.title), \(conversation.time), \(conversation.department)"
        row.accessibilityTraits = .button
        return row
    }

    private func highlightedTitle(_ title: String, query: String) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: title,
            attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: AppStyle.ink]
        )
        guard !query.isEmpty, let range = title.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else { return result }
        let nsRange = NSRange(range, in: title)
        result.addAttributes([.foregroundColor: AppStyle.blue, .font: UIFont.systemFont(ofSize: 15, weight: .medium)], range: nsRange)
        return result
    }

    private func image(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        renderConversations()
        view.endEditing(true)
        return true
    }
}