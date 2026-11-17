import UIKit

extension UIView {
    func addPassthroughSubview(_ subview: UIView) {
        subview.isUserInteractionEnabled = false
        addSubview(subview)
    }
}
