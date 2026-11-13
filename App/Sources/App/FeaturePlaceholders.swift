import UIKit

@MainActor
final class ChatHomeViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "채팅"; addHeading("채팅") }
}

@MainActor
final class CommunityViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "커뮤니티"; addHeading("커뮤니티") }
}

@MainActor
final class HistoryViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "기록"; addHeading("지난 대화") }
}

@MainActor
final class MyPageViewController: AppPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); title = "마이페이지"; addHeading("마이페이지") }
}
