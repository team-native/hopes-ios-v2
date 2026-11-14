import UIKit

@MainActor
final class AppTabBarController: UITabBarController {
    private struct TabItem {
        let controller: UIViewController
        let title: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let brandBlue = UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1)
        let tertiary = UIColor(red: 156 / 255, green: 171 / 255, blue: 194 / 255, alpha: 1)
        let softBlue = UIColor(red: 229 / 255, green: 245 / 255, blue: 1, alpha: 1)
        let tabFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
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
        appearance.selectionIndicatorImage = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 30)).image { _ in
            softBlue.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 30), cornerRadius: 15).fill()
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        let tabs: [TabItem] = [
            TabItem(controller: HomeViewController(), title: "홈"),
            TabItem(controller: ChatHomeViewController(), title: "채팅"),
            TabItem(controller: HistoryViewController(), title: "기록"),
            TabItem(controller: MyPageViewController(), title: "설정")
        ]
        viewControllers = makeNavigationControllers(for: tabs)
    }

    private func makeNavigationControllers(for tabs: [TabItem]) -> [UIViewController] {
        tabs.map { item in
            let navigation = UINavigationController(rootViewController: item.controller)
            navigation.tabBarItem = UITabBarItem(
                title: item.title,
                image: makeTabIcon(isSelected: false),
                selectedImage: makeTabIcon(isSelected: true)
            )
            return navigation
        }
    }

    private func makeTabIcon(isSelected: Bool) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        return UIGraphicsImageRenderer(size: size).image { context in
            let circle = UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: 10, height: 10))
            if isSelected {
                context.cgContext.setFillColor(UIColor.black.cgColor)
                circle.fill()
            } else {
                context.cgContext.setStrokeColor(UIColor.black.cgColor)
                context.cgContext.setLineWidth(1)
                circle.stroke()
            }
        }.withRenderingMode(.alwaysTemplate)
    }
}
