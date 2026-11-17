import UIKit

final class TouchExpandingStackView: UIStackView {
    var touchInsets = UIEdgeInsets(top: -14, left: 0, bottom: -12, right: 0)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.inset(by: touchInsets).contains(point)
    }
}
