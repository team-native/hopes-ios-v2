import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = AppStyle.blue
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
        let tabs: [(UIViewController, String, String)] = [
            (HomeViewController(), "홈", "house"),
            (ChatHomeViewController(), "채팅", "bubble.left.and.bubble.right"),
            (CommunityViewController(), "커뮤니티", "person.2"),
            (HistoryViewController(), "기록", "clock.arrow.circlepath"),
            (MyPageViewController(), "마이페이지", "person.crop.circle")
        ]
        viewControllers = tabs.map { controller, title, image in
            let navigation = UINavigationController(rootViewController: controller)
            navigation.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: image), selectedImage: nil)
            return navigation
        }
    }
}
