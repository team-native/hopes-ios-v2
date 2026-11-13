import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
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
        let tabs: [(UIViewController, String, String, String?)] = [
            (HomeViewController(), "홈", "home-tab-icon-inactive", "home-tab-icon"),
            (ChatHomeViewController(), "채팅", "chat-tab-icon", nil),
            (CommunityViewController(), "커뮤니티", "community-tab-icon", nil),
            (HistoryViewController(), "기록", "history-tab-icon", nil),
            (MyPageViewController(), "마이페이지", "mypage-tab-icon", "mypage-tab-icon-selected")
        ]
        viewControllers = tabs.map { controller, title, image, selectedImage in
            let navigation = UINavigationController(rootViewController: controller)
            let icon = UIImage(named: image)?.withRenderingMode(.alwaysTemplate)
            let selectedIcon = selectedImage.flatMap { UIImage(named: $0)?.withRenderingMode(.alwaysTemplate) } ?? icon
            navigation.tabBarItem = UITabBarItem(title: title, image: icon, selectedImage: selectedIcon)
            return navigation
        }
    }
}
