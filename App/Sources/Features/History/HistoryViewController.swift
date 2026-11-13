import UIKit

@MainActor
final class HistoryViewController: AppPageViewController, UITextFieldDelegate {
    private struct Conversation {
        let title: String
        let time: String
        let department: String
        let olderThanWeek: Bool
    }

    private var conversations: [Conversation] = ProcessInfo.processInfo.arguments.contains("--empty-history") ? [] : [
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
    private var newConversationButton: UIView?
    private weak var revealedRow: ConversationRowView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "기록"
        contentStack.spacing = 14
        if conversations.isEmpty {
            navigationController?.setNavigationBarHidden(true, animated: false)
            addEmptyHistoryState()
            return
        }

        addHeading("지난 대화", subtitle: "이전 대화를 이어서 볼 수 있어요.")
        addSearchField()

        periodControl.selectedSegmentIndex = 0
        periodControl.addAction(UIAction { [weak self] _ in self?.renderConversations() }, for: .valueChanged)
        contentStack.addArrangedSubview(periodControl)
        contentStack.addArrangedSubview(resultsCountLabel)

        resultsStack.axis = .vertical
        contentStack.addArrangedSubview(resultsStack)
        renderConversations()

        let newConversation = AppStyle.button("새 대화 시작", primary: true) { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        }
        newConversationButton = newConversation
        contentStack.addArrangedSubview(newConversation)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(conversations.isEmpty, animated: animated)
    }

    private func addEmptyHistoryState() {
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

        let icon = UIImageView(image: image(named: "history-empty-chat"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36)
        ])

        let title = AppStyle.label("아직 대화가 없어요", size: 18, weight: .medium)
        title.textAlignment = .center
        let subtitle = AppStyle.label("선배에게 첫 질문을 해보세요.", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "채팅 시작하기"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.addAction(UIAction { [weak self] _ in
            self?.tabBarController?.selectedIndex = 1
        }, for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [illustration, title, subtitle, button])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12

        let container = UIView()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.72),
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        contentStack.addArrangedSubview(container)
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
        newConversationButton?.isHidden = isSearching

        let isOlderSelected = periodControl.selectedSegmentIndex == 1
        let filtered = conversations.filter { conversation in
            (isSearching || conversation.olderThanWeek == isOlderSelected)
                && (query.isEmpty || conversation.title.localizedCaseInsensitiveContains(query))
        }
        resultsCountLabel.isHidden = isSearching && filtered.isEmpty
        resultsCountLabel.text = isSearching ? "검색 결과 \(filtered.count)개" : "지난 대화 \(filtered.count)개"
        guard !filtered.isEmpty else {
            if isSearching {
                resultsStack.addArrangedSubview(makeNoSearchResultsState())
            } else {
                resultsStack.addArrangedSubview(AppStyle.label("대화 기록이 없어요", size: 14, color: AppStyle.muted))
            }
            return
        }
        addConversationCard(filtered, query: query)
    }

    private func makeNoSearchResultsState() -> UIView {
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
            let row = makeConversationRow(conversation, query: query)
            rows.addArrangedSubview(row)
            if index < conversations.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor(red: 0.90, green: 0.93, blue: 0.97, alpha: 1)
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                rows.addArrangedSubview(divider)
            }
        }
        resultsStack.addArrangedSubview(card)
    }

    private func makeConversationRow(_ conversation: Conversation, query: String) -> ConversationRowView {
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
        }
        row.configure(content: content, trashImage: UIImage(systemName: "trash"))
        return row
    }

    private func confirmDeletion(of conversation: Conversation, from row: ConversationRowView?) {
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

@MainActor
private final class ConversationRowView: UIView, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)?
    var onDelete: (() -> Void)?
    var onBeginSwipe: (() -> Void)?

    private let revealWidth: CGFloat = 80
    private let contentButton = UIButton(type: .custom)
    private let deleteButton = UIButton(type: .system)
    private var startOffset: CGFloat = 0
    private var offset: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(content: UIView, trashImage: UIImage?) {
        content.translatesAutoresizingMaskIntoConstraints = false
        contentButton.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentButton.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: contentButton.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: contentButton.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: contentButton.bottomAnchor, constant: -14)
        ])
        var configuration = UIButton.Configuration.plain()
        configuration.image = trashImage
        configuration.imagePlacement = .top
        configuration.imagePadding = 2
        configuration.title = "삭제"
        configuration.baseForegroundColor = .white
        configuration.contentInsets = .zero
        deleteButton.configuration = configuration
        deleteButton.addAction(UIAction { [weak self] _ in self?.onDelete?() }, for: .touchUpInside)
        contentButton.addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
    }

    func setRevealed(_ revealed: Bool, animated: Bool) {
        offset = revealed ? -revealWidth : 0
        let changes = { self.contentButton.transform = CGAffineTransform(translationX: self.offset, y: 0) }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: changes)
        } else {
            changes()
        }
    }

    private func build() {
        backgroundColor = UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1)
        clipsToBounds = true

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: topAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: revealWidth)
        ])

        contentButton.backgroundColor = .white
        contentButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentButton)
        NSLayoutConstraint.activate([
            contentButton.topAnchor.constraint(equalTo: topAnchor),
            contentButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        contentButton.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self).x
        switch gesture.state {
        case .began:
            startOffset = offset
            onBeginSwipe?()
        case .changed:
            offset = min(0, max(-revealWidth, startOffset + translation))
            contentButton.transform = CGAffineTransform(translationX: offset, y: 0)
        case .ended, .cancelled, .failed:
            setRevealed(offset <= -revealWidth / 2, animated: true)
        default:
            break
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }
}
