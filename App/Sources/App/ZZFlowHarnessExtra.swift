#if DEBUG
  import UIKit

  @MainActor
  enum ZZFlowHarnessExtra {
    static let controllers: [String: () -> UIViewController] = [
      "postdelete": { after(mine()) { $0.confirmPostDeletion() } },
      "liked": { after(other()) { $0.toggleLike() } },
      "commentkb": { after(other()) { $0.commentField.becomeFirstResponder() } },
      "commentmore": {
        after(other()) { controller in
          guard let label = controller.editingCommentLabel else { return }
          controller.showOwnCommentActions(text: label.text ?? "", label: label)
        }
      },
      "commentedit": {
        after(other()) { controller in
          guard let label = controller.editingCommentLabel else { return }
          controller.beginCommentEdit(text: label.text ?? "", label: label)
        }
      },
      "writekb": { afterWrite { $0.bodyView.becomeFirstResponder() } },
      "writeerr": {
        afterWrite { controller in
          controller.titleField.text = ""
          controller.bodyView.text = ""
          controller.publish()
        }
      },
      "writeexit": {
        afterWrite { controller in
          controller.titleField.text = "기숙사 와이파이 다들 잘 돼?"
          (controller.view.firstDescendant(id: "community-write-close") as? UIButton)?.sendActions(for: .touchUpInside)
        }
      },
      "writefail": {
        afterWrite { controller in
          controller.titleField.text = "기숙사 와이파이 다들 잘 돼?"
          controller.showRegistrationFailure()
        }
      },
      "writedone": {
        CommunityPostStore.shared.markPostPublished(board: "10기")
        return CommunityViewController()
      },
      "historynone": {
        let controller = HistoryViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          controller.searchField.text = "축제"
          controller.renderConversations()
        }
        return controller
      },
      "historyswipe": {
        let controller = HistoryViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          (controller.view.firstDescendant(type: ConversationRowView.self))?.setRevealed(true, animated: false)
        }
        return controller
      },
      "historydelete": {
        let controller = HistoryViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          controller.confirmDeletion(of: controller.conversations[0], from: nil)
        }
        return controller
      },
      "announcement": { AnnouncementDetailViewController() },
      "profilesaved": {
        UserProfileStore.shared.markProfileSaved()
        return MyPageViewController()
      },
      "profilekb": {
        let controller = EditProfileViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { controller.introductionView.becomeFirstResponder() }
        return controller
      },
      "promptkb": {
        let controller = AIAnswerStyleViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { controller.promptView.becomeFirstResponder() }
        return controller
      },
      "logout": {
        let controller = SettingsViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          (controller.view.firstDescendant(id: "settings-logout") as? UIButton)?.sendActions(for: .touchUpInside)
        }
        return controller
      },
      "postedit": { CommunityPostEditViewController(post: CommunityPostStore.shared.myPosts[0]) },
      "reportdone": {
        let controller = CommunityPostDetailViewController(post: CommunityPostStore.shared.posts[0])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          let flow = CommunityReportFlowViewController()
          controller.present(flow, animated: false)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            (flow.view.firstDescendant(id: "community-report-submit") as? UIButton)?
              .sendActions(for: .touchUpInside)
          }
        }
        return controller
      },
      "dupreport": {
        after(other()) { controller in
          CommunityPostStore.shared.markReported(CommunityPostStore.shared.posts[0])
          controller.showReportReasons()
        }
      },
      "actempty": {
        CommunityPostStore.shared.myPosts = []
        CommunityPostStore.shared.myComments = []
        return MyActivityViewController()
      }
    ]

    private static func other() -> CommunityPostDetailViewController {
      CommunityPostDetailViewController(post: CommunityPostStore.shared.posts[0])
    }

    private static func mine() -> CommunityPostDetailViewController {
      CommunityPostDetailViewController(post: CommunityPostStore.shared.myPosts[0], isMine: true)
    }

    private static func after(
      _ controller: CommunityPostDetailViewController,
      _ apply: @escaping (CommunityPostDetailViewController) -> Void
    ) -> UIViewController {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { apply(controller) }
      return controller
    }

    private static func afterWrite(_ apply: @escaping (CommunityWriteViewController) -> Void) -> UIViewController {
      let controller = CommunityWriteViewController()
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { apply(controller) }
      return controller
    }
  }

  extension UIView {
    func firstDescendant<T: UIView>(type: T.Type) -> T? {
      if let match = self as? T { return match }
      for child in subviews {
        if let match = child.firstDescendant(type: type) { return match }
      }
      return nil
    }

    func firstDescendant(id: String) -> UIView? {
      if accessibilityIdentifier == id { return self }
      for child in subviews {
        if let match = child.firstDescendant(id: id) { return match }
      }
      return nil
    }
  }
#endif
