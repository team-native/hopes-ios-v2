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
    func firstDescendant(id: String) -> UIView? {
      if accessibilityIdentifier == id { return self }
      for child in subviews {
        if let match = child.firstDescendant(id: id) { return match }
      }
      return nil
    }
  }
#endif
