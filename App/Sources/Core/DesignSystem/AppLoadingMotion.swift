import UIKit

@MainActor
enum AppLoadingMotion {
    static let pulseKey = "app.loading.pulse"
    static let blinkKey = "app.loading.blink"
    static let bounceKey = "app.loading.bounce"

    static var isEnabled: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }

    static func pulse(_ view: UIView) {
        guard isEnabled else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.45
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = false
        view.layer.add(animation, forKey: pulseKey)
    }

    static func blink(_ view: UIView) {
        guard isEnabled else { return }
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [1, 1, 0, 0]
        animation.keyTimes = [0, 0.5, 0.5, 1]
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        view.layer.add(animation, forKey: blinkKey)
    }

    static func bounce(_ dots: [UIView]) {
        guard isEnabled else { return }
        let start = CACurrentMediaTime()
        for (index, dot) in dots.enumerated() {
            let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
            animation.values = [0, -4, 0, 0]
            animation.keyTimes = [0, 0.2, 0.4, 1]
            animation.duration = 1.1
            animation.beginTime = start + Double(index) * 0.15
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.isRemovedOnCompletion = false
            dot.layer.add(animation, forKey: bounceKey)
        }
    }
}
