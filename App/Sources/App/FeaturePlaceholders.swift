import UIKit

@MainActor
final class MyPageViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "마이페이지"; addHeading("마이페이지") }
}
