import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--inquiry-error-preview") {
            window.rootViewController = UINavigationController(rootViewController: InquiryViewController())
        } else if arguments.contains("--inquiry-done-preview") {
            window.rootViewController = UINavigationController(
                rootViewController: InquiryCompletionViewController(email: "s26055@gsm.hs.kr")
            )
        } else if arguments.contains("--settings-preview") {
            let tabs = AppTabBarController()
            tabs.selectedIndex = 3
            window.rootViewController = tabs
        } else {
            window.rootViewController = WelcomeViewController()
        }
        self.window = window
        (UIApplication.shared.delegate as? AppDelegate)?.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              appDelegate.window === window else { return }
        appDelegate.window = nil
    }
}
