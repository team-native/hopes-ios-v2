#if DEBUG
import UIKit
import CoreLocation
  @MainActor
  enum ZZResetHarness {
    static func root(_ target: String) -> UIViewController {
      let reset = PasswordResetViewController()
      let nav = UINavigationController(rootViewController: LoginViewController())
      nav.setNavigationBarHidden(true, animated: false)
      nav.pushViewController(reset, animated: false)
      func type(_ field: UITextField, _ text: String) {
        field.text = text
        field.sendActions(for: .editingChanged)
      }
      let toCode: [(PasswordResetViewController) -> Void] = [
        { type($0.emailField, "s26055@gsm.hs.kr") }, { $0.performPrimaryAction() }
      ]
      let toNew = toCode + [{ type($0.codeField, "482913") }, { $0.performPrimaryAction() }]
      let filled =
        toNew + [
          { type($0.newPasswordField, "hopes2026!") },
          { type($0.confirmPasswordField, "hopes2026!") }
        ]
      var steps: [(PasswordResetViewController) -> Void]
      switch target {
      case "02-8":
        steps = [{ type($0.emailField, "nobody@gsm.hs.kr") }, { $0.performPrimaryAction() }]
      case "02-9": steps = toCode + [{ type($0.codeField, "4821") }]
      case "02-10": steps = filled
      case "02-11": steps = filled + [{ $0.performPrimaryAction() }]
      default: steps = [{ type($0.emailField, "s26055@gsm.hs.kr") }]
      }
      for (index, step) in steps.enumerated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(index) * 0.35) {
          MainActor.assumeIsolated { step(reset) }
        }
      }
      return nav
    }
  }

  @MainActor
  enum ZZLoc {
    static func make(_ apply: @escaping (ChatConversationViewController) -> Void)
      -> UIViewController {
      let controller = ChatConversationViewController(question: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        controller.setLocationConversationHeader(active: true)
        controller.addUserMessage("지금 내 위치 알려줘", isLocationRequest: true)
        controller.hasPendingLocationRequest = true
        apply(controller)
      }
      return controller
    }
  }

  @MainActor
  enum ZZAtt {
    static func make(_ apply: @escaping (ChatConversationViewController) -> Void)
      -> UIViewController {
      let controller = ChatConversationViewController(question: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { apply(controller) }
      return controller
    }

    static func pdfURL() -> URL {
      let url = FileManager.default.temporaryDirectory.appendingPathComponent("sample.pdf")
      let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 300, height: 400)).pdfData { ctx in
        ctx.beginPage()
        ("입학 안내" as NSString).draw(
          at: CGPoint(x: 20, y: 20), withAttributes: [.font: UIFont.systemFont(ofSize: 20)])
      }
      try? data.write(to: url)
      return url
    }

    static func samples() -> [ChatAttachmentItem] {
      let image = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300)).image { ctx in
        UIColor(red: 0.8, green: 0.88, blue: 0.98, alpha: 1).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
      }
      return [
        ChatAttachmentItem(fileName: "기숙사_시간표.jpg", image: image),
        ChatAttachmentItem(fileName: "입학안내.pdf", image: nil, url: pdfURL(), pageCount: 1)
      ]
    }
  }

#endif
