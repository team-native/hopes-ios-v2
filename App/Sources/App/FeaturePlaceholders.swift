import UIKit

@MainActor
final class HistoryViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "기록"; addHeading("지난 대화") }
}

@MainActor
final class MyPageViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "마이페이지"; addHeading("마이페이지") }
}
