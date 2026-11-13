import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
    private struct TabItem {
        let controller: UIViewController
        let title: String
        let image: String
        let selectedImage: String?
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
        appearance.shadowColor = AppStyle.line
        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = tertiary
        normal.titleTextAttributes = [.font: tabFont, .foregroundColor: tertiary]
        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = brandBlue
        selected.titleTextAttributes = [.font: tabFont, .foregroundColor: brandBlue]
        appearance.selectionIndicatorImage = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 56)).image { _ in
            softBlue.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 56), cornerRadius: 16).fill()
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        let tabs: [TabItem] = [
            TabItem(controller: HomeViewController(), title: "홈", image: "home-tab-icon-inactive", selectedImage: "home-tab-icon"),
            TabItem(controller: ChatHomeViewController(), title: "채팅", image: "chat-tab-icon", selectedImage: nil),
            TabItem(controller: CommunityViewController(), title: "커뮤니티", image: "community-tab-icon", selectedImage: nil),
            TabItem(controller: HistoryViewController(), title: "기록", image: "history-tab-icon", selectedImage: nil),
            TabItem(controller: MyPageViewController(), title: "마이페이지", image: "mypage-tab-icon", selectedImage: "mypage-tab-icon-selected")
        ]
        viewControllers = tabs.map { item in
            let navigation = UINavigationController(rootViewController: item.controller)
            let icon = UIImage(named: item.image)?.withRenderingMode(.alwaysTemplate)
            let selectedIcon = item.selectedImage.flatMap {
                UIImage(named: $0)?.withRenderingMode(.alwaysTemplate)
            } ?? icon
            navigation.tabBarItem = UITabBarItem(title: item.title, image: icon, selectedImage: selectedIcon)
            return navigation
        }
    }
}
