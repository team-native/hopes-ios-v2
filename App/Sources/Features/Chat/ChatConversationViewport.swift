import UIKit

@MainActor
extension ChatConversationViewController {
    func scrollToLatestMessage() {
        view.layoutIfNeeded()
        let inset = scrollView.adjustedContentInset
        let bottom = max(-inset.top, scrollView.contentSize.height - scrollView.bounds.height + inset.bottom)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottom), animated: false)
    }

    func focusAfterAnswer() {
        guard viewIfLoaded?.window != nil,
              presentedViewController == nil,
              navigationController?.topViewController === self,
              UIApplication.shared.applicationState == .active else { return }
        inputField.becomeFirstResponder()
        scrollToLatestMessage()
    }
}
