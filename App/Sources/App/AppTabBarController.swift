import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
    private struct TabItem {
        let controller: UIViewController
        let title: String
        let iconName: String
        let selectedSymbolName: String
        let identifier: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        let tabFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        tabBar.tintColor = brandBlue
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1)
        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = tertiary
        normal.titleTextAttributes = [.font: tabFont, .foregroundColor: tertiary]
        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = brandBlue
        selected.titleTextAttributes = [.font: tabFont, .foregroundColor: brandBlue]
        let indicator = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 52)).image { _ in
            softBlue.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 64, height: 52), cornerRadius: 16).fill()
        }
        appearance.selectionIndicatorImage = indicator.withRenderingMode(.alwaysOriginal)
        appearance.selectionIndicatorTintColor = softBlue
        tabBar.selectionIndicatorImage = indicator.withRenderingMode(.alwaysOriginal)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        let tabs: [TabItem] = [
            TabItem(
                controller: HomeViewController(), title: "홈", iconName: "home-tab-icon-inactive",
                selectedSymbolName: "house", identifier: "home"
            ),
            TabItem(
                controller: ChatHomeViewController(), title: "채팅", iconName: "chat-tab-icon",
                selectedSymbolName: "bubble.left", identifier: "chat"
            ),
            TabItem(
                controller: CommunityViewController(), title: "커뮤니티", iconName: "community-tab-icon",
                selectedSymbolName: "person.2", identifier: "community"
            ),
            TabItem(
                controller: HistoryViewController(), title: "기록", iconName: "history-tab-icon",
                selectedSymbolName: "clock", identifier: "history"
            ),
            TabItem(
                controller: MyPageViewController(), title: "마이페이지", iconName: "mypage-tab-icon",
                selectedSymbolName: "person", identifier: "mypage"
            )
        ]
        viewControllers = makeNavigationControllers(for: tabs)
    }

    private func makeNavigationControllers(for tabs: [TabItem]) -> [UIViewController] {
        tabs.map { item in
            let navigation = UINavigationController(rootViewController: item.controller)
            navigation.tabBarItem = UITabBarItem(
                title: item.title,
                image: UIImage(named: item.iconName)?.withRenderingMode(.alwaysOriginal),
                selectedImage: selectedImage(for: item)
            )
            navigation.tabBarItem.accessibilityIdentifier = "tab-\(item.identifier)"
            return navigation
        }
    }

    private func selectedImage(for item: TabItem) -> UIImage? {
        UIImage(systemName: item.selectedSymbolName)?.withRenderingMode(.alwaysTemplate)
    }
}
