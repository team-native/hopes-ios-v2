import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
    private struct TabItem {
        let controller: UIViewController
        let title: String
        let identifier: String
    }

    private let customBar = UIView()
    private var tabButtons: [UIButton] = []
    private let tabRowHeight: CGFloat = 56
    private let tabBarBorder = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    private var requestedSelectedIndex = 0
    private var didHandleSessionExpiredPreview = false

    override var selectedIndex: Int {
        get { super.selectedIndex }
        set {
            requestedSelectedIndex = newValue
            super.selectedIndex = newValue
            updateSelection()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tabs: [TabItem] = [
            TabItem(
                controller: HomeViewController(), title: "홈", identifier: "home"
            ),
            TabItem(
                controller: ChatHomeViewController(), title: "채팅", identifier: "chat"
            ),
            TabItem(
                controller: CommunityViewController(), title: "커뮤니티", identifier: "community"
            ),
            TabItem(
                controller: HistoryViewController(), title: "기록", identifier: "history"
            ),
            TabItem(
                controller: MyPageViewController(), title: "마이페이지", identifier: "mypage"
            )
        ]
        let initialIndex = requestedSelectedIndex
        viewControllers = makeNavigationControllers(for: tabs)
        if initialIndex < tabs.count {
            selectedIndex = initialIndex
        }
        configureNativeTabBarForNavigationCompatibility()
        configureCustomBar(for: tabs)
        delegate = self
        updateSelection()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionExpired),
            name: .authSessionDidExpire,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didHandleSessionExpiredPreview,
           ProcessInfo.processInfo.arguments.contains("--session-expired-preview") {
            didHandleSessionExpiredPreview = true
            AuthSessionRouter.notifySessionExpired()
        }
    }

    @objc private func handleSessionExpired() {
        guard view.window != nil else { return }
        var top: UIViewController = self
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        AuthSessionRouter.presentSessionExpiredAlert(from: top)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let shouldShowBar = !tabBar.isHidden
        customBar.isHidden = !shouldShowBar
        if let parent = tabBar.superview {
            parent.bringSubviewToFront(customBar)
        }
    }

    private func configureNativeTabBarForNavigationCompatibility() {
        tabBar.alpha = 0
        tabBar.isUserInteractionEnabled = false
        tabBar.backgroundColor = .white
    }

    private func configureCustomBar(for tabs: [TabItem]) {
        customBar.backgroundColor = .white
        customBar.translatesAutoresizingMaskIntoConstraints = false
        guard let parent = tabBar.superview else { return }
        parent.insertSubview(customBar, aboveSubview: tabBar)
        let separator = UIView()
        separator.backgroundColor = tabBarBorder
        separator.translatesAutoresizingMaskIntoConstraints = false
        customBar.addSubview(separator)
        NSLayoutConstraint.activate([
            customBar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            customBar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            customBar.topAnchor.constraint(equalTo: tabBar.topAnchor),
            customBar.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            separator.topAnchor.constraint(equalTo: customBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: customBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: customBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])

        let row = makeTabRow(for: tabs)
        customBar.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: customBar.leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: customBar.trailingAnchor, constant: -8),
            row.topAnchor.constraint(equalTo: customBar.topAnchor, constant: 8),
            row.heightAnchor.constraint(equalToConstant: tabRowHeight)
        ])
    }

    private func makeTabRow(for tabs: [TabItem]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false

        for (index, item) in tabs.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.accessibilityIdentifier = "tab-\(item.identifier)"
            button.accessibilityLabel = item.title
            button.accessibilityTraits = .button
            button.addAction(UIAction { [weak self] action in
                guard let button = action.sender as? UIButton else { return }
                self?.selectedIndex = button.tag
                self?.updateSelection()
            }, for: .touchUpInside)

            let icon = UIImageView()
            icon.tag = 100
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            let label = UILabel()
            label.tag = 101
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.text = item.title
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(icon)
            button.addSubview(label)
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 56),
                icon.topAnchor.constraint(equalTo: button.topAnchor, constant: 8),
                icon.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                icon.widthAnchor.constraint(equalToConstant: 22),
                icon.heightAnchor.constraint(equalToConstant: 22),
                label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 2),
                label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
                label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
                label.bottomAnchor.constraint(lessThanOrEqualTo: button.bottomAnchor, constant: -3)
            ])
            row.addArrangedSubview(button)
            tabButtons.append(button)
        }
        return row
    }

    private func makeNavigationControllers(for tabs: [TabItem]) -> [UIViewController] {
        tabs.map { item in
            let navigation = AppNavigationController(rootViewController: item.controller)
            navigation.tabBarItem = UITabBarItem(title: item.title, image: nil, tag: 0)
            navigation.tabBarItem.accessibilityIdentifier = "tab-\(item.identifier)"
            return navigation
        }
    }

    private func updateSelection() {
        let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        let inactive = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        let selectedFill = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        for (index, button) in tabButtons.enumerated() {
            let isSelected = index == selectedIndex
            button.backgroundColor = isSelected ? selectedFill : .clear
            button.layer.cornerRadius = 16
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
            (button.viewWithTag(101) as? UILabel)?.textColor = isSelected ? blue : inactive
            guard let icon = button.viewWithTag(100) as? UIImageView else { continue }
            let assetNames = iconNames(isSelected: isSelected)
            icon.image = UIImage(named: assetNames[index])?.withRenderingMode(.alwaysOriginal)
        }
    }

    private func iconNames(isSelected: Bool) -> [String] {
        if isSelected {
            return [
                "home-tab-icon", "chat-tab-icon", "community-tab-icon", "history-tab-icon",
                "mypage-tab-icon-selected"
            ]
        }
        return [
            "home-tab-icon-inactive", "chat-tab-icon-inactive", "community-tab-icon-inactive",
            "history-tab-icon-inactive", "mypage-tab-icon"
        ]
    }
}

extension AppTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateSelection()
    }
}
