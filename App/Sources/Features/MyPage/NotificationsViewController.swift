import UIKit

@MainActor
final class NotificationsViewController: AppPageViewController {
    struct NotificationItem {
        let title: String
        let detail: String
        let category: String
        let question: String?
        var isRead: Bool
    }

    var items: [NotificationItem] = ProcessInfo.processInfo.arguments.contains("--notifications-empty") ? [] : [
        NotificationItem(title: "새 답변 도착", detail: "기숙사 질문에 선배 답변이 도착했어요.", category: "답변",
            question: "기숙사 하루 일과가 어떻게 돼?", isRead: false),
        NotificationItem(title: "프로필 저장 완료", detail: "개인화 정보가 반영됐어요.", category: "프로필", question: nil, isRead: false),
        NotificationItem(title: "입학 안내 업데이트", detail: "면접 준비 질문이 추가됐어요.", category: "입학", question: nil, isRead: true),
        NotificationItem(title: "시스템 공지", detail: "답변 데이터 업데이트 완료", category: "공지", question: nil, isRead: true)
    ]

    let itemsStack = UIStackView()
    private let isLoadingPreview = ProcessInfo.processInfo.arguments.contains("--notifications-loading")
    private let isEmptyPreview = ProcessInfo.processInfo.arguments.contains("--notifications-empty")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        contentStack.spacing = 16
        addNotificationsHeader()

        if isLoadingPreview {
            addLoadingSkeleton()
            return
        }
        if items.isEmpty {
            addEmptyState()
            return
        }

        itemsStack.axis = .vertical
        itemsStack.spacing = 10
        contentStack.addArrangedSubview(itemsStack)
        addMarkAllReadButton()
        renderItems()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addNotificationsHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "notifications-back-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backButton.accessibilityLabel = "뒤로"
        backButton.accessibilityIdentifier = "notifications-back"
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("알림", size: 18, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255,
            blue: 43 / 255, alpha: 1))
        let subtitle = AppStyle.label("새 답변과 공지 알림을 확인해요.", size: 12, color: UIColor(red: 107 / 255,
            green: 120 / 255, blue: 144 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 0

        var headerItems: [UIView] = [backButton, labels, UIView()]
        if !isLoadingPreview && !isEmptyPreview {
            let editButton = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = "편집"
            configuration.baseForegroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 14, weight: .medium)
                return outgoing
            }
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            editButton.configuration = configuration
            editButton.backgroundColor = .white
            editButton.layer.cornerRadius = 10
            editButton.layer.borderWidth = 1
            editButton.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
            editButton.accessibilityIdentifier = "notifications-edit"
            headerItems.append(editButton)
        }

        let header = UIStackView(arrangedSubviews: headerItems)
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addMarkAllReadButton() {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = "모두 읽음 처리"
        configuration.baseForegroundColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        button.configuration = configuration
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        button.addTarget(self, action: #selector(markAllRead), for: .touchUpInside)
        button.accessibilityIdentifier = "notifications-mark-all-read"
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        contentStack.addArrangedSubview(button)
    }

    private func addLoadingSkeleton() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)

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

        for _ in 0..<4 {
            let icon = UIView()
            icon.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 1)
            icon.layer.cornerRadius = 12
            icon.widthAnchor.constraint(equalToConstant: 36).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 36).isActive = true

            let primaryLine = skeletonLine(width: 220, height: 12, radius: 6)
            let secondaryLine = skeletonLine(width: 140, height: 10, radius: 5)
            let lines = UIStackView(arrangedSubviews: [primaryLine, secondaryLine])
            lines.axis = .vertical
            lines.spacing = 8

            let row = UIStackView(arrangedSubviews: [icon, lines])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.isLayoutMarginsRelativeArrangement = true
            row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
            rows.addArrangedSubview(row)
        }
        contentStack.addArrangedSubview(card)
    }

}

@MainActor
extension NotificationsViewController {
    private func addEmptyState() {
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

        let bell = UIImageView(image: UIImage(systemName: "bell"))
        bell.tintColor = AppStyle.blue
        bell.contentMode = .scaleAspectFit
        bell.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(bell)
        NSLayoutConstraint.activate([
            bell.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            bell.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            bell.widthAnchor.constraint(equalToConstant: 36),
            bell.heightAnchor.constraint(equalToConstant: 36)
        ])

        let title = AppStyle.label("새 알림이 없어요", size: 18, weight: .medium)
        title.textAlignment = .center
        let subtitle = AppStyle.label("새 답변과 공지가 여기에 쌓여요.", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center

        let content = UIStackView(arrangedSubviews: [illustration, title, subtitle])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12

        let container = UIView()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.9),
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        contentStack.addArrangedSubview(container)
    }

    private func skeletonLine(width: CGFloat, height: CGFloat, radius: CGFloat) -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 1)
        line.layer.cornerRadius = radius
        line.widthAnchor.constraint(equalToConstant: width).isActive = true
        line.heightAnchor.constraint(equalToConstant: height).isActive = true
        return line
    }

}

@MainActor
extension NotificationsViewController {
    func renderItems() {
        itemsStack.arrangedSubviews.forEach { view in
            itemsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        guard !items.isEmpty else {
            itemsStack.addArrangedSubview(AppStyle.label("새로운 알림이 없어요", size: 14, color: AppStyle.muted))
            return
        }
        itemsStack.backgroundColor = .white
        itemsStack.layer.cornerRadius = 24
        itemsStack.layer.borderWidth = 1
        itemsStack.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        itemsStack.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        itemsStack.layer.shadowOpacity = 0.05
        itemsStack.layer.shadowRadius = 4
        itemsStack.layer.shadowOffset = CGSize(width: 0, height: 4)
        itemsStack.isLayoutMarginsRelativeArrangement = true
        itemsStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 17, bottom: 14, trailing: 17)
        itemsStack.spacing = 0
        items.enumerated().forEach { index, item in
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                itemsStack.addArrangedSubview(divider)
            }
            itemsStack.addArrangedSubview(makeNotificationRow(item, index: index))
        }
    }

}

@MainActor
extension NotificationsViewController {
    func makeNotificationRow(_ item: NotificationItem, index: Int) -> UIControl {
        let row = makeNotificationRowContent(item, index: index)
        addNotificationSelection(to: row, item: item, index: index)
        return row
    }

    private func makeNotificationRowContent(_ item: NotificationItem, index: Int) -> UIControl {
        let iconName: String
        switch item.category {
        case "답변": iconName = "notifications-chat-icon"
        case "프로필": iconName = "notifications-user-icon"
        case "입학": iconName = "notifications-file-icon"
        default: iconName = "notifications-bell-icon"
        }
        let chip = UIView()
        chip.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        chip.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        chip.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chip.widthAnchor.constraint(equalToConstant: 40),
            chip.heightAnchor.constraint(equalToConstant: 40),
            icon.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20)
        ])

        let title = AppStyle.label(item.title, size: 15, weight: .medium, color: UIColor(red: 20 / 255,
            green: 27 / 255, blue: 43 / 255, alpha: 1))
        title.numberOfLines = 1
        let detail = AppStyle.label(item.detail, size: 12, color: UIColor(red: 107 / 255, green: 120 / 255,
            blue: 144 / 255, alpha: 1))
        detail.numberOfLines = 1
        let labels = UIStackView(arrangedSubviews: [title, detail])
        labels.axis = .vertical
        labels.spacing = 2

        let viewLabel = AppStyle.label("보기", size: 14, weight: .medium, color: UIColor(red: 47 / 255,
            green: 134 / 255, blue: 245 / 255, alpha: 1))
        viewLabel.setContentHuggingPriority(.required, for: .horizontal)
        let content = UIStackView(arrangedSubviews: [chip, labels, viewLabel])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12

        let row = UIControl()
        row.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -14)
        ])
        row.accessibilityLabel = "\(item.title), \(item.detail), 보기"
        row.accessibilityIdentifier = "notification-row-\(index)"
        return row
    }

    private func addNotificationSelection(to row: UIControl, item: NotificationItem, index: Int) {
        row.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.items[index].isRead = true
            if let question = item.question {
                self.push(ChatConversationViewController(question: question))
            } else if item.category == "프로필" {
                self.push(EditProfileViewController())
            } else {
                self.push(AnnouncementDetailViewController())
            }
        }, for: .touchUpInside)
    }

    @objc func markAllRead() {
        items = items.map { item in
            var updated = item
            updated.isRead = true
            return updated
        }
        renderItems()
    }
}
