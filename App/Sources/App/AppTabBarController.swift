import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = AppStyle.blue
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = AppStyle.line
        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(red: 156 / 255, green: 171 / 255, blue: 194 / 255, alpha: 1)
        normal.titleTextAttributes = [.foregroundColor: UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1)]
        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1)
        selected.titleTextAttributes = [.foregroundColor: UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1)]
        appearance.selectionIndicatorImage = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 30)).image { _ in
            UIColor(red: 229 / 255, green: 245 / 255, blue: 1, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 30), cornerRadius: 15).fill()
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        let tabs: [(UIViewController, String, String)] = [
            (HomeViewController(), "홈", "house"),
            (ChatHomeViewController(), "채팅", "bubble.left.and.bubble.right"),
            (HistoryViewController(), "기록", "clock.arrow.circlepath"),
            (SettingsViewController(), "설정", "gearshape")
        ]
        viewControllers = tabs.map { controller, title, image in
            let navigation = UINavigationController(rootViewController: controller)
            navigation.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: image), selectedImage: nil)
            return navigation
        }
    }
}
