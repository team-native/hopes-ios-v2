import UIKit

@MainActor
final class HistoryViewController: AppPageViewController, UITextFieldDelegate {
    struct Conversation {
        let title: String
        let time: String
        let department: String
        let olderThanWeek: Bool
    }

    var conversations: [Conversation] = ProcessInfo.processInfo.arguments.contains("--empty-history") ? [] : [
        Conversation(title: "기숙사 하루 일과가 어떻게 돼?", time: "어제", department: "소프트웨어개발과", olderThanWeek: false),
        Conversation(title: "전공 선택은 어떻게 하는 게 좋아?", time: "어제", department: "소프트웨어개발과", olderThanWeek: false),
        Conversation(title: "동아리는 언제 정해?", time: "지난주", department: "소프트웨어개발과", olderThanWeek: false),
        Conversation(title: "입학하려면 뭘 준비해야 해?", time: "10월 28일", department: "소프트웨어개발과", olderThanWeek: true),
        Conversation(title: "과랑 전공이랑 뭐가 달라?", time: "10월 21일", department: "소프트웨어개발과", olderThanWeek: true),
        Conversation(title: "후배한테 해주고 싶은 조언 있어?", time: "10월 18일", department: "소프트웨어개발과", olderThanWeek: true)
    ]

    let searchField = UITextField()
    let resultsStack = UIStackView()
    let clearSearchButton = UIButton(type: .system)
    var newConversationButton: UIView?
    weak var revealedRow: ConversationRowView?
    private var conversationRows: [ConversationRowView] = []
    private var isSearchingResults = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "기록"
        view.backgroundColor = UIColor(red: 0.965, green: 0.976, blue: 0.988, alpha: 1)
        contentStack.spacing = 16
        contentStack.setCustomSpacing(24, after: resultsStack)
        if conversations.isEmpty {
            navigationController?.setNavigationBarHidden(true, animated: false)
            addHistoryHeading()
            addEmptyHistoryState()
            return
        }

        addHistoryHeading()
        addSearchField()

        resultsStack.axis = .vertical
        resultsStack.spacing = 16
        contentStack.addArrangedSubview(resultsStack)
        renderConversations()

        addNewConversationButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(conversations.isEmpty, animated: animated)
    }

}

@MainActor
extension HistoryViewController {
    private func addSearchField() {
        let searchIcon = UIImageView(image: image(named: "history-search"))
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        searchIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true

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
        fieldRow.spacing = 8
        fieldRow.isLayoutMarginsRelativeArrangement = true
        fieldRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        fieldRow.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 24
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        container.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.10).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.addSubview(fieldRow)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 48),
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

    func renderConversations() {
        resultsStack.arrangedSubviews.forEach { view in
            resultsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isSearching = !query.isEmpty
        isSearchingResults = isSearching
        conversationRows.removeAll()
        clearSearchButton.isHidden = !isSearching
        newConversationButton?.isHidden = isSearching

        let filtered = conversations.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
        guard !filtered.isEmpty else {
            if isSearching {
                resultsStack.addArrangedSubview(makeNoSearchResultsState())
            } else {
                resultsStack.addArrangedSubview(AppStyle.label("대화 기록이 없어요", size: 14, color: AppStyle.muted))
            }
            return
        }
        if isSearching {
            addConversationCard(filtered, query: query)
            return
        }

        addConversationSection("지난 7일", conversations: filtered.filter { !$0.olderThanWeek }, query: query)
        addConversationSection("이전", conversations: filtered.filter(\.olderThanWeek), query: query)
    }

    func makeNoSearchResultsState() -> UIView {
        let illustration = UIView()
        illustration.backgroundColor = .white
        illustration.layer.cornerRadius = 44
        illustration.layer.borderWidth = 1
        illustration.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        illustration.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.10).cgColor
        illustration.layer.shadowOpacity = 1
        illustration.layer.shadowRadius = 14
        illustration.layer.shadowOffset = CGSize(width: 0, height: 8)
        illustration.widthAnchor.constraint(equalToConstant: 88).isActive = true
        illustration.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let icon = UIImageView(image: image(named: "history-search-empty"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36)
        ])

        let title = AppStyle.label("검색 결과가 없어요", size: 18, weight: .medium)
        title.textAlignment = .center
        let subtitle = AppStyle.label("다른 단어로 검색해 보세요.", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center
        let content = UIStackView(arrangedSubviews: [illustration, title, subtitle])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12

        let container = UIView()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.55),
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    func addConversationSection(_ title: String, conversations: [Conversation], query: String) {
        guard !conversations.isEmpty else { return }
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 8
        let heading = AppStyle.label(title, size: 14, weight: .medium, color: UIColor(red: 0.42, green: 0.47,
            blue: 0.56, alpha: 1))
        section.addArrangedSubview(heading)
        section.addArrangedSubview(makeConversationCard(conversations, query: query))
        resultsStack.addArrangedSubview(section)
    }

    func addConversationCard(_ conversations: [Conversation], query: String) {
        resultsStack.addArrangedSubview(makeConversationCard(conversations, query: query))
    }

    func makeConversationCard(_ conversations: [Conversation], query: String) -> UIView {
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
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        for (index, conversation) in conversations.enumerated() {
            let row = makeConversationRow(conversation, query: query)
            rows.addArrangedSubview(row)
            if index < conversations.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor(red: 0.90, green: 0.93, blue: 0.97, alpha: 1)
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                rows.addArrangedSubview(divider)
            }
        }
        return card
    }

    func makeConversationRow(_ conversation: Conversation, query: String) -> ConversationRowView {
        let title = UILabel()
        title.attributedText = highlightedTitle(conversation.title, query: query)
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let metadataText = query.isEmpty ? conversation.time : "\(conversation.time) · \(conversation.department)"
        let metadata = AppStyle.label(metadataText, size: 12, color: UIColor(red: 152 / 255, green: 163 / 255,
            blue: 184 / 255, alpha: 1))
        metadata.attributedText = NSAttributedString(string: metadataText, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1),
            .paragraphStyle: lineStyle(height: 16)
        ])
        metadata.heightAnchor.constraint(equalToConstant: 16).isActive = true
        metadata.isHidden = query.isEmpty
        let text = UIStackView(arrangedSubviews: [title, metadata])
        text.axis = .vertical
        text.spacing = 2
        let chevron = UIImageView(image: image(named: "history-chevron"))
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let content = UIStackView(arrangedSubviews: [text, chevron])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        let row = ConversationRowView()
        row.accessibilityLabel = "\(conversation.title), \(conversation.time), \(conversation.department)"
        row.accessibilityTraits = .button
        row.onOpen = { [weak self] in
            self?.push(ChatConversationViewController(question: conversation.title))
        }
        row.onDelete = { [weak self, weak row] in
            self?.confirmDeletion(of: conversation, from: row)
        }
        row.onBeginSwipe = { [weak self, weak row] in
            guard let self, let row, self.revealedRow !== row else { return }
            self.revealedRow?.setRevealed(false, animated: true)
            self.revealedRow = row
            self.conversationRows.forEach { $0.setMetadataVisible(true) }
        }
        row.onSwipeEnded = { [weak self, weak row] isRevealed in
            guard let self, let row, !isRevealed, self.revealedRow === row else { return }
            self.revealedRow = nil
            self.conversationRows.forEach { $0.setMetadataVisible(self.isSearchingResults) }
        }
        row.configure(content: content,
            trashImage: UIImage(named: "HistorySwipeTrash")?.withRenderingMode(.alwaysOriginal), metadataLabel: metadata)
        conversationRows.append(row)
        return row
    }

    func confirmDeletion(of conversation: Conversation, from row: ConversationRowView?) {
        row?.setRevealed(false, animated: true)
        if revealedRow === row { revealedRow = nil }

        let alert = UIAlertController(
            title: "이 대화를 삭제할까요?",
            message: "삭제한 대화는 되돌릴 수 없어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.conversations.removeAll { $0.title == conversation.title && $0.time == conversation.time }
            self.renderConversations()
        })
        present(alert, animated: true)
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

    func image(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        renderConversations()
        view.endEditing(true)
        return true
    }
}
