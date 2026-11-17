import UIKit

final class AppNavigationController: UINavigationController, UINavigationControllerDelegate {
    var onDidShow: ((UINavigationController) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if !viewControllers.isEmpty {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController,
                              animated: Bool) {
        if viewController !== navigationController.viewControllers.first {
            onDidShow?(navigationController)
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController,
                              animated: Bool) {
        onDidShow?(navigationController)
    }
}
