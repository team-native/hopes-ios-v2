import UIKit

@MainActor
final class HomeViewController: AppPageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "홈"
        addHeading("Hopes", subtitle: "앱 화면을 연결하고 있어요")
    }
}
