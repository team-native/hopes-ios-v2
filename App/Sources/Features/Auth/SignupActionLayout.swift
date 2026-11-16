import UIKit

@MainActor
extension SignupViewController {
    func updateActionSpacer(keyboardVisible: Bool) {
        guard step != .complete,
              let actionTopSpacer,
              let actionTopSpacerHeightConstraint else { return }
        guard !keyboardVisible else {
            actionTopSpacerHeightConstraint.constant = 14
            return
        }

        view.layoutIfNeeded()
        let targetBottom = view.bounds.maxY - AppStyle.bottomActionInset
        let targetTop = targetBottom - 50
        let spacerTop = actionTopSpacer.convert(.zero, to: view).y
        actionTopSpacerHeightConstraint.constant = max(14, targetTop - spacerTop)
        view.layoutIfNeeded()
    }
}
