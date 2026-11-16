import UIKit

@MainActor
final class HistoryViewController: AppPageViewController, UITextFieldDelegate {
    struct Conversation {
        var id: Int64?
        let title: String
        let time: String
        let department: String
        let olderThanWeek: Bool
    }

    private let showsSearchPreview = ProcessInfo.processInfo.arguments.contains("--history-search-preview")
    var conversations: [Conversation] = {
        let arguments = ProcessInfo.processInfo.arguments
        guard !arguments.contains("--empty-history"), !AccessTokenStore.shared.hasToken else { return [] }
        var conversations = [
            Conversation(title: "기숙사 하루 일과가 어떻게 돼?", time: "어제", department: "소프트웨어개발과", olderThanWeek: false),
            Conversation(title: "전공 선택은 어떻게 하는 게 좋아?", time: "2일 전", department: "소프트웨어개발과", olderThanWeek: false),
            Conversation(title: "동아리는 언제 정해?", time: "5일 전", department: "소프트웨어개발과", olderThanWeek: false),
            Conversation(title: "입학하려면 뭘 준비해야 해?", time: "10월 28일", department: "소프트웨어개발과", olderThanWeek: true),
            Conversation(title: "과랑 전공이랑 뭐가 달라?", time: "10월 21일", department: "소프트웨어개발과", olderThanWeek: true),
            Conversation(title: "후배한테 해주고 싶은 조언 있어?", time: "10월 18일", department: "소프트웨어개발과", olderThanWeek: true)
        ]
        if arguments.contains("--history-search-preview") {
            conversations.append(Conversation(
                title: "기숙사 방 배정은 어떻게 돼?",
                time: "3일 전",
                department: "소프트웨어개발과",
                olderThanWeek: false
            ))
        }
        return conversations
    }()

    let searchField = UITextField()
    let resultsStack = UIStackView()
    let clearSearchButton = UIButton(type: .system)
    var newConversationButton: UIView?
    weak var revealedRow: ConversationRowView?
    private var searchContainer: UIView?
    private var conversationRows: [ConversationRowView] = []
    private var isSearchingResults = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "기록"
        navigationController?.setNavigationBarHidden(true, animated: false)
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .bottom
        })?.constant = -16
        contentStack.heightAnchor.constraint(
            greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, constant: -24
        ).isActive = true
        let preferredHeight = contentStack.heightAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.heightAnchor, constant: -24
        )
        preferredHeight.priority = .defaultLow - 1
        preferredHeight.isActive = true
        view.backgroundColor = UIColor(red: 0.965, green: 0.976, blue: 0.988, alpha: 1)
        contentStack.spacing = 16
        buildContent()
    }

    func buildContent() {
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        conversationRows.removeAll()
        if conversations.isEmpty {
            addHistoryHeading()
            addEmptyHistoryState()
            return
        }

        addHistoryHeading()
        addSearchField()
        if showsSearchPreview {
            searchField.text = "기숙사"
        }

        resultsStack.axis = .vertical
        resultsStack.spacing = 16
        contentStack.addArrangedSubview(resultsStack)
        let spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        contentStack.addArrangedSubview(spacer)
        addNewConversationButton()
        renderConversations()
        if showsSearchPreview {
            DispatchQueue.main.async { [weak self] in
                self?.searchField.becomeFirstResponder()
            }
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadConversations()
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
        searchContainer = container
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
            container.heightAnchor.constraint(equalToConstant: 50),
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

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField === searchField else { return }
        searchContainer?.layer.borderWidth = 1.5
        let focusColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
        searchContainer?.layer.borderColor = focusColor.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === searchField else { return }
        searchContainer?.layer.borderWidth = 1
        let normalColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
        searchContainer?.layer.borderColor = normalColor.cgColor
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
        resultsStack.spacing = isSearching ? 14 : 16
        if let searchContainer { contentStack.setCustomSpacing(isSearching ? 14 : 16, after: searchContainer) }
        newConversationButton?.isHidden = isSearching

        let filtered = conversations.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
        guard !filtered.isEmpty else {
            if isSearching {
                let emptyState = makeNoSearchResultsState()
                resultsStack.addArrangedSubview(emptyState)
                emptyState.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.55)
                    .isActive = true
            } else {
                resultsStack.addArrangedSubview(AppStyle.label("대화 기록이 없어요", size: 14, color: AppStyle.muted))
            }
            return
        }
        if isSearching {
            let resultCount = AppStyle.label(
                "검색 결과 \(filtered.count)개",
                size: 14,
                weight: .medium,
                color: AppStyle.muted
            )
            resultCount.heightAnchor.constraint(equalToConstant: 20).isActive = true
            resultsStack.addArrangedSubview(resultCount)
            addConversationCard(filtered, query: query)
            return
        }

        addConversationSection("지난 7일", conversations: filtered.filter { !$0.olderThanWeek }, query: query)
        addConversationSection("이전", conversations: filtered.filter(\.olderThanWeek), query: query)
    }

    func addConversationSection(_ title: String, conversations: [Conversation], query: String) {
        guard !conversations.isEmpty else { return }
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 16
        let heading = AppStyle.label(title, size: 14, weight: .medium, color: UIColor(red: 0.42, green: 0.47,
            blue: 0.56, alpha: 1))
        heading.heightAnchor.constraint(equalToConstant: 20).isActive = true
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
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15)
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
        row.onOpen = { [weak self] in self?.openConversation(conversation) }
        row.onDelete = { [weak self, weak row] in
            self?.confirmDeletion(of: conversation, from: row)
        }
        configureSwipe(for: row)
        let trashImage = UIImage(named: "HistorySwipeTrash")?.withRenderingMode(.alwaysOriginal)
        row.configure(content: content, trashImage: trashImage, metadataLabel: metadata)
        conversationRows.append(row)
        return row
    }

    func configureSwipe(for row: ConversationRowView) {
        row.onBeginSwipe = { [weak self, weak row] in
            guard let self, let row, self.revealedRow !== row else { return }
            self.revealedRow?.setRevealed(false, animated: true)
            self.revealedRow = row
            self.conversationRows.forEach {
                $0.setMetadataVisible(true)
                $0.setSwipeLayout(true)
            }
        }
        row.onSwipeEnded = { [weak self, weak row] isRevealed in
            guard let self, let row, !isRevealed, self.revealedRow === row else { return }
            self.revealedRow = nil
            self.conversationRows.forEach {
                $0.setMetadataVisible(self.isSearchingResults)
                $0.setSwipeLayout(false)
            }
        }
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
            Task {
                if let id = conversation.id {
                    do {
                        try await ChatAPI.delete(id: id)
                    } catch {
                        self.showMessage((error as? APIError)?.message ?? "대화를 삭제하지 못했어요.")
                        return
                    }
                }
                self.conversations.removeAll { $0.title == conversation.title && $0.time == conversation.time }
                self.buildContent()
            }
        })
        present(alert, animated: true)
    }

    func image(named name: String) -> UIImage? {
        UIImage(named: name)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        renderConversations()
        view.endEditing(true)
        return true
    }
}
