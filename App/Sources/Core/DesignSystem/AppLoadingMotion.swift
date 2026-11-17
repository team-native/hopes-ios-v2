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

    static func makeLoadingDots(color: UIColor = AppStyle.blue, size: CGFloat = 8) -> UIView {
        let dots = (0..<3).map { _ in
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = size / 2
            dot.widthAnchor.constraint(equalToConstant: size).isActive = true
            dot.heightAnchor.constraint(equalToConstant: size).isActive = true
            return dot
        }
        let row = UIStackView(arrangedSubviews: dots)
        row.axis = .horizontal
        row.spacing = size * 0.75
        row.alignment = .center
        row.accessibilityIdentifier = "loading-dots"
        row.isAccessibilityElement = true
        row.accessibilityLabel = "답변을 만드는 중"
        let container = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: size + 12)
        ])
        bounce(dots)
        dots.enumerated().forEach { index, dot in
            guard isEnabled else { return }
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0.35, 1, 0.35, 0.35]
            fade.keyTimes = [0, 0.2, 0.4, 1]
            fade.duration = 1.1
            fade.beginTime = CACurrentMediaTime() + Double(index) * 0.15
            fade.repeatCount = .infinity
            fade.isRemovedOnCompletion = false
            dot.layer.add(fade, forKey: "app.loading.fade")
        }
        return container
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
