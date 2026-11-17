#if DEBUG
  import CoreLocation
  import UIKit
  @MainActor
  // State routing table for manual Figma inspection in Debug builds.
  // swiftlint:disable:next type_body_length
  enum ZZFlowHarness {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func root(for arguments: [String]) -> UIViewController? {
      if let resetArg = arguments.first(where: { $0.hasPrefix("--h-reset=") }) {
        return ZZResetHarness.root(String(resetArg.dropFirst("--h-reset=".count)))
      }
      if let tabArg = arguments.first(where: { $0.hasPrefix("--h-tab=") }),
        let index = Int(tabArg.dropFirst(8)) {
        let tabs = AppTabBarController()
        tabs.selectedIndex = index
        return tabs
      }
      if arguments.contains("--h-map") {
        return UINavigationController(rootViewController: ChatLocationViewController(accuracy: 12))
      }
      if let pushArg = arguments.first(where: { $0.hasPrefix("--h-push=") }) {
        let tabs = AppTabBarController()
        let name = String(pushArg.dropFirst(9))
        let controllers: [String: () -> UIViewController] = [
          "write": { CommunityWriteViewController() },
          "search": { CommunitySearchViewController() },
          "noti": { NotificationsViewController() },
          "activity": { MyActivityViewController() },
          "inquiry": { InquiryViewController() },
          "profile": { EditProfileViewController() },
          "style": { AIAnswerStyleViewController() },
          "appinfo": { AppInfoViewController() },
          "settings": { SettingsViewController() },
          "deletion": { AccountDeletionViewController() },
          "loc-perm": { ZZLoc.make { $0.showLocationPermissionCard() } },
          "loc-measure": { ZZLoc.make { $0.showLocationMeasurementCard() } },
          "loc-fail": { ZZLoc.make { $0.showLocationFailure() } },
          "loc-ok": {
            ZZLoc.make {
              $0.showLocationOutcome(
                for: CLLocation(
                  coordinate: CLLocationCoordinate2D(latitude: 35.1428, longitude: 126.8002),
                  altitude: 0, horizontalAccuracy: 12, verticalAccuracy: 5, timestamp: Date()),
                serverStatus: "INSIDE")
            }
          },
          "loc-out": {
            ZZLoc.make {
              $0.measuredLocation = CLLocationCoordinate2D(latitude: 35.16, longitude: 126.85)
              $0.showLocationOutcome(
                for: CLLocation(
                  coordinate: CLLocationCoordinate2D(latitude: 35.16, longitude: 126.85),
                  altitude: 0, horizontalAccuracy: 20, verticalAccuracy: 5, timestamp: Date()),
                serverStatus: "OUTSIDE")
            }
          },
          "loc-low": {
            ZZLoc.make {
              $0.showLocationOutcome(
                for: CLLocation(
                  coordinate: CLLocationCoordinate2D(latitude: 35.1428, longitude: 126.8002),
                  altitude: 0, horizontalAccuracy: 180, verticalAccuracy: 5, timestamp: Date()),
                serverStatus: "LOW_ACCURACY")
            }
          },
          "att-sheet": {
            ZZAtt.make { controller in
              controller.present(ChatAttachmentPickerViewController(), animated: false)
            }
          },
          "att-preview": {
            ZZAtt.make { controller in controller.addAttachments(ZZAtt.samples()) }
          },
          "att-unsupported": {
            ZZAtt.make { controller in
              controller.addAttachments(
                ZZAtt.samples() + [
                  ChatAttachmentItem(
                    fileName: "회의록.hwp", image: nil, validationState: .unsupportedFormat)
                ])
            }
          },
          "att-limit": {
            ZZAtt.make { controller in
              controller.addAttachments(
                ZZAtt.samples() + [
                  ChatAttachmentItem(
                    fileName: "큰파일.pdf", image: nil, url: ZZAtt.pdfURL(),
                    validationState: .fileTooLarge)
                ])
            }
          },
          "att-badpdf": {
            ZZAtt.make { controller in
              controller.addAttachments([
                ChatAttachmentItem(
                  fileName: "잠긴문서.pdf", image: nil, url: ZZAtt.pdfURL(),
                  validationState: .unreadablePDF)
              ])
            }
          },
          "att-send": {
            ZZAtt.make { controller in
              controller.addAttachments(ZZAtt.samples())
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task { _ = await controller.sendAttachmentQuestion("이 자료 기준으로 준비물 정리해줘") }
              }
            }
          },
          "post": { CommunityPostDetailViewController(post: ZZCommunityFixture.post) },
          "mypost": {
            CommunityPostDetailViewController(
              post: ZZCommunityFixture.post, isMine: true)
          },
          "postmore": {
            let controller = CommunityPostDetailViewController(
              post: ZZCommunityFixture.post)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { controller.showPostActions() }
            return controller
          },
          "mypostmore": {
            let controller = CommunityPostDetailViewController(
              post: ZZCommunityFixture.post, isMine: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { controller.showPostActions() }
            return controller
          },
          "report": {
            let controller = CommunityPostDetailViewController(
              post: ZZCommunityFixture.post)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              controller.present(CommunityReportFlowViewController(), animated: false)
            }
            return controller
          },
          "boardpicker": {
            let controller = CommunityWriteViewController()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              controller.present(
                CommunityBoardPickerViewController(selectedBoard: "10기"), animated: false)
            }
            return controller
          },
          "deleted": {
            CommunityPostDetailViewController(
              post: CommunityPost(
                grade: "10기", title: "삭제된 글", body: "", time: "", comments: 0, likes: 0,
                category: "질문"))
          },
          "commentfail": {
            let controller = CommunityPostDetailViewController(
              post: ZZCommunityFixture.post)
            controller.shouldSimulateCommentFailure = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              controller.commentField.text = "저녁엔 3층도 느려요"
              controller.submitComment()
            }
            return controller
          },
          "searchnone": {
            let controller = CommunitySearchViewController()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              controller.searchField.text = "수학여행 일정"
              controller.runSearch()
            }
            return controller
          },
          "actcomments": {
            let controller = MyActivityViewController()
            controller.selectedTab = 1
            return controller
          },
          "chatok": {
            let controller = ChatConversationViewController(question: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              controller.addUserMessage("프론트엔드는 뭐부터 공부하면 좋아?")
              controller.addMarkdownAnswer(
                "## Frontend 시작 순서\n" +
                "처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요.\n" +
                "1. HTML·CSS로 간단한 페이지 만들기\n" +
                "2. JavaScript 기초 문법 익히기\n" +
                "3. React로 작은 프로젝트 완성하기\n" +
                "```html\n" +
                "<button class=\"primary\">\n" +
                "  질문하기\n" +
                "</button>\n" +
                "```\n" +
                "> 막히면 선배에게 바로 물어보는 게 제일 빨라요.\n" +
                "[학교 전공 소개 페이지 보기](https://gsm.hs.kr)"
              )
            }
            return controller
          },
          "chatfail": {
            let controller = ChatConversationViewController(question: "기숙사 하루 일과가 어떻게 돼?")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              controller.stopAnswerGeneration()
            }
            return controller
          },
          "chatoff": {
            let controller = ChatConversationViewController(question: "기숙사 하루 일과가 어떻게 돼?")
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
              controller.updateNetworkStatus(isOffline: true)
            }
            return controller
          },
          "chatkb": {
            let controller = ChatConversationViewController(question: "기숙사 하루 일과가 어떻게 돼?")
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
              controller.inputField.becomeFirstResponder()
            }
            return controller
          },
          "deletionkb": {
            let controller = AccountDeletionViewController()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
              controller.passwordField.becomeFirstResponder()
            }
            return controller
          },
          "privacy": { PrivacyPolicyViewController() },
          "chat": { ChatConversationViewController(question: "기숙사 하루 일과가 어떻게 돼?") }
        ]
        tabs.selectedIndex = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          MainActor.assumeIsolated {
            guard let make = controllers[name] ?? ZZFlowHarnessExtra.controllers[name],
              let nav = tabs.selectedViewController as? UINavigationController
            else { return }
            let controller = make()
            controller.hidesBottomBarWhenPushed = true
            nav.pushViewController(controller, animated: false)
          }
        }
        return tabs
      }
      if arguments.contains("--h-deleted") {
        let welcome = WelcomeViewController()
        welcome.pendingToastMessage = "탈퇴가 완료됐어요"
        return welcome
      }
      if let homeArg = arguments.first(where: { $0.hasPrefix("--h-chathome=") }) {
        let state = String(homeArg.dropFirst("--h-chathome=".count))
        let tabs = AppTabBarController()
        tabs.selectedIndex = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          MainActor.assumeIsolated {
            guard let nav = tabs.selectedViewController as? UINavigationController,
              let home = nav.topViewController as? ChatHomeViewController
            else { return }
            switch state {
            case "fail": home.showRecommendationState(.failed)
            case "loading": home.showRecommendationState(.loading)
            case "unselected":
              home.selectedDepartment = nil
              home.selectedMajor = nil
              home.updateContextChipTitles()
              home.loadRecommendations()
            case "kb": home.fillQuestion("Frontend는 뭐부터 공부하면 좋아?")
            case "dept": home.selectDepartment()
            case "major": home.selectMajor()
            default: break
            }
          }
        }
        return tabs
      }
      if let boardArg = arguments.first(where: { $0.hasPrefix("--h-board=") }) {
        let board = String(boardArg.dropFirst("--h-board=".count))
        let tabs = AppTabBarController()
        tabs.selectedIndex = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          MainActor.assumeIsolated {
            ((tabs.selectedViewController as? UINavigationController)?.topViewController
              as? CommunityViewController)?.selectBoard(board)
          }
        }
        return tabs
      }
      if arguments.contains("--h-board10") {
        let tabs = AppTabBarController()
        tabs.selectedIndex = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          MainActor.assumeIsolated {
            ((tabs.selectedViewController as? UINavigationController)?.topViewController
              as? CommunityViewController)?.selectBoard("10기")
          }
        }
        return tabs
      }
      if arguments.contains("--h-home") {
        return AppTabBarController()
      }
      if arguments.contains("--h-login-test") {
        let welcome = WelcomeViewController()
        welcome.opensLoginOnAppear = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
          MainActor.assumeIsolated {
            guard let nav = welcome.presentedViewController as? UINavigationController,
              let login = nav.viewControllers.first as? LoginViewController
            else { return }
            login.emailField.text = "nobody-test@gsm.hs.kr"
            login.passwordField.text = "wrongpass1"
            login.login()
          }
        }
        return welcome
      }
      if arguments.contains("--h-login-password") {
        let welcome = WelcomeViewController()
        welcome.opensLoginOnAppear = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
          MainActor.assumeIsolated {
            guard let nav = welcome.presentedViewController as? UINavigationController,
              let login = nav.viewControllers.first as? LoginViewController
            else { return }
            login.emailField.text = "s26055@gsm.hs.kr"
            login.passwordField.becomeFirstResponder()
          }
        }
        return welcome
      }
      if arguments.contains("--h-onboarding") {
        return UINavigationController(rootViewController: OnboardingViewController())
      }
      guard let arg = arguments.first(where: { $0.hasPrefix("--h-signup=") }) else { return nil }
      let target = String(arg.dropFirst("--h-signup=".count))
      let signup = SignupViewController()
      let nav = UINavigationController(rootViewController: signup)
      nav.setNavigationBarHidden(true, animated: false)
      var steps: [(SignupViewController) -> Void] = []
      func type(_ field: UITextField, _ text: String) {
        field.text = text
        field.sendActions(for: .editingChanged)
      }
      let order = ["03", "03-3", "03-6", "03-7", "03-9", "03-10", "03-11"]
      let toVerification: [(SignupViewController) -> Void] = [
        { type($0.emailField, "s\(Int.random(in: 10000...99999))@gsm.hs.kr") },
        { $0.performPrimaryAction() }
      ]
      let toVerified =
        toVerification + [{ type($0.codeField, "482913") }, { $0.performPrimaryAction() }]
      let toPassword = toVerified + [{ $0.performPrimaryAction() }]
      let toPasswordReady =
        toPassword + [
          { type($0.passwordField, "hopes2026!") }, { type($0.confirmField, "hopes2026!") },
          { $0.performPrimaryAction() }
        ]
      let toProfile = toPasswordReady + [{ $0.performPrimaryAction() }]
      _ = order
      switch target {
      case "03": steps = [{ _ in }]
      case "03-1":
        steps = [{ type($0.emailField, "student@gmail.com") }, { $0.performPrimaryAction() }]
      case "03-2":
        steps = [{ type($0.emailField, "taken@gsm.hs.kr") }, { $0.performPrimaryAction() }]
      case "03-3": steps = toVerification + [{ type($0.codeField, "48") }]
      case "03-4":
        steps = toVerification + [{ type($0.codeField, "48291") }, { $0.performPrimaryAction() }]
      case "03-5":
        steps = toVerification + [{ $0.countdownDeadline = Date().addingTimeInterval(1) }]
      case "03-6": steps = toVerified
      case "03-7": steps = toPassword + [{ type($0.passwordField, "hopes") }]
      case "03-8":
        steps =
          toPassword + [
            { type($0.passwordField, "abc") }, { type($0.confirmField, "abd") },
            { $0.performPrimaryAction() }
          ]
      case "03-9": steps = toPasswordReady
      case "03-10": steps = toProfile
      case "03-10-2": steps = toProfile + [{ $0.showGenerationPicker() }]
      case "03-11":
        steps =
          toProfile + [
            { $0.generation = "10기" }, { $0.generationError = false },
            { $0.render(focusField: false) },
            { $0.performPrimaryAction() },
            { controller in
              let frame = controller.actionButton.convert(controller.actionButton.bounds, to: nil)
              NSLog(
                "ZZDEBUG button=%@ inset=%@ offset=%@ frame=%@", NSCoder.string(for: frame),
                NSCoder.string(for: controller.scrollView.contentInset),
                NSCoder.string(for: controller.scrollView.contentOffset),
                NSCoder.string(for: controller.scrollView.frame))
            }
          ]
      default: break
      }
      for (index, step) in steps.enumerated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(index) * 0.35) {
          MainActor.assumeIsolated { step(signup) }
        }
      }
      return nav
    }
  }

#endif
