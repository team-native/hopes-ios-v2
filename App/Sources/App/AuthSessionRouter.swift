import UIKit

extension Notification.Name {
    static let authSessionDidExpire = Notification.Name("kr.hs.gsm.hopes.authSessionDidExpire")
}

@MainActor
enum AuthSessionRouter {
    private static weak var activeSessionExpiredAlert: UIAlertController?

    static func notifySessionExpired() {
        NotificationCenter.default.post(name: .authSessionDidExpire, object: nil)
    }

    static func logOut() {
        Task { await AuthAPI.logout() }
        replaceRoot(with: WelcomeViewController())
    }

    static func showHome() {
        replaceRoot(with: AppTabBarController())
    }

    static func finishAccountDeletion() {
        AccessTokenStore.shared.clear()
        UserProfileStore.shared.clearLocalData()
        let welcome = WelcomeViewController()
        welcome.pendingToastMessage = "탈퇴가 완료됐어요"
        replaceRoot(with: welcome)
    }

    static func showLogin() {
        AccessTokenStore.shared.clear()
        let welcome = WelcomeViewController()
        welcome.opensLoginOnAppear = true
        replaceRoot(with: welcome)
    }

    static func presentSessionExpiredAlert(from presenter: UIViewController) {
        guard activeSessionExpiredAlert?.presentingViewController == nil else { return }
        let alert = makeSessionExpiredAlert()
        activeSessionExpiredAlert = alert
        presenter.present(alert, animated: true)
    }

    private static func makeSessionExpiredAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "다시 로그인해 주세요",
            message: "보안을 위해 로그인이 만료됐어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        let login = UIAlertAction(title: "로그인", style: .default) { _ in showLogin() }
        alert.addAction(login)
        alert.preferredAction = login
        return alert
    }

    private static func replaceRoot(with controller: UIViewController) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let window = appDelegate.window else { return }
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
}
