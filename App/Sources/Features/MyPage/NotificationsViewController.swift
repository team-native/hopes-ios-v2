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

    private var items: [NotificationItem] = ProcessInfo.processInfo.arguments.contains("--notifications-empty") ? [] : [
        NotificationItem(title: "내 질문에 새 답변이 달렸어요", detail: "기숙사 하루 일과가 어떻게 돼? · 10분 전", category: "답변", question: "기숙사 하루 일과가 어떻게 돼?", isRead: false),
        NotificationItem(title: "게시글에 댓글이 달렸어요", detail: "기숙사 와이파이 다들 잘 돼? · 1시간 전", category: "답변", question: "기숙사 와이파이 다들 잘 돼?", isRead: false),
        NotificationItem(title: "이번 주 학교 일정 안내", detail: "학교 공지 · 어제", category: "공지", question: nil, isRead: true)
    ]

    private let categoryControl = UISegmentedControl(items: ["전체", "답변", "공지"])
    private let itemsStack = UIStackView()
    private var selectedCategory = "전체"
    private let isLoadingPreview = ProcessInfo.processInfo.arguments.contains("--notifications-loading")
    private let isEmptyPreview = ProcessInfo.processInfo.arguments.contains("--notifications-empty")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addNotificationsHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = AppStyle.ink
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("알림", size: 18, weight: .medium)
        let subtitle = AppStyle.label("새 답변과 공지 알림을 확인해요.", size: 12, color: AppStyle.muted)
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 0

        var headerItems: [UIView] = [backButton, labels, UIView()]
        if !isLoadingPreview && !isEmptyPreview {
            let markAllReadButton = UIButton(type: .system)
            markAllReadButton.setTitle("모두 읽음", for: .normal)
            markAllReadButton.setTitleColor(AppStyle.blue, for: .normal)
            markAllReadButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            markAllReadButton.addTarget(self, action: #selector(markAllRead), for: .touchUpInside)
            headerItems.append(markAllReadButton)
        }

        let header = UIStackView(arrangedSubviews: headerItems)
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
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
