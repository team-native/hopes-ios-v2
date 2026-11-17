import UIKit

@MainActor
final class AppCountUpAnimator {
    private weak var label: UILabel?
    private let startValue: Int
    private let target: Int
    private let duration: CFTimeInterval
    private var startTime: CFTimeInterval?
    private var displayLink: CADisplayLink?
    private var retainedSelf: AppCountUpAnimator?

    private init(label: UILabel, start: Int, target: Int, duration: CFTimeInterval) {
        self.label = label
        self.startValue = start
        self.target = target
        self.duration = duration
    }

    static func animate(_ label: UILabel, from start: Int, to target: Int, duration: CFTimeInterval = 0.8) {
        guard start != target, !UIAccessibility.isReduceMotionEnabled else {
            setValue(target, on: label)
            return
        }
        let animator = AppCountUpAnimator(label: label, start: start, target: target, duration: duration)
        animator.start()
    }

    nonisolated static func value(from start: Int, to target: Int, progress: Double) -> Int {
        let clamped = min(max(progress, 0), 1)
        let eased = 1 - pow(1 - clamped, 3)
        return start + Int((Double(target - start) * eased).rounded())
    }

    static func setValue(_ value: Int, on label: UILabel) {
        let text = "\(value)"
        guard let current = label.attributedText, current.length > 0 else {
            label.text = text
            return
        }
        let attributes = current.attributes(at: 0, effectiveRange: nil)
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
    }

    private func start() {
        retainedSelf = self
        if let label { Self.setValue(startValue, on: label) }
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func step(_ link: CADisplayLink) {
        guard let label else { return finish() }
        let began = startTime ?? link.timestamp
        startTime = began
        let progress = (link.timestamp - began) / duration
        Self.setValue(Self.value(from: startValue, to: target, progress: progress), on: label)
        if progress >= 1 { finish() }
    }

    private func finish() {
        displayLink?.invalidate()
        displayLink = nil
        retainedSelf = nil
    }
}
