import UIKit

@MainActor
final class ChatConversationBubbleView: UIView {
    private let shapeLayer = CAShapeLayer()
    private let topLeftRadius: CGFloat
    private let topRightRadius: CGFloat
    private let bottomRightRadius: CGFloat
    private let bottomLeftRadius: CGFloat

    init(
        fillColor: UIColor,
        topLeftRadius: CGFloat,
        topRightRadius: CGFloat,
        bottomRightRadius: CGFloat,
        bottomLeftRadius: CGFloat,
        borderColor: UIColor? = nil
    ) {
        self.topLeftRadius = topLeftRadius
        self.topRightRadius = topRightRadius
        self.bottomRightRadius = bottomRightRadius
        self.bottomLeftRadius = bottomLeftRadius
        super.init(frame: .zero)
        backgroundColor = .clear
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.strokeColor = borderColor?.cgColor
        shapeLayer.lineWidth = borderColor == nil ? 0 : 1
        if borderColor != nil {
            shapeLayer.shadowColor = UIColor(
                red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.03
            ).cgColor
            shapeLayer.shadowOpacity = 1
            shapeLayer.shadowRadius = 1.5
            shapeLayer.shadowOffset = CGSize(width: 0, height: 1)
        }
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = bubblePath()
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
        layer.shadowPath = path.cgPath
    }

    private func bubblePath() -> UIBezierPath {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let maximumRadius = min(rect.width, rect.height) / 2
        let topLeft = min(topLeftRadius, maximumRadius)
        let topRight = min(topRightRadius, maximumRadius)
        let bottomRight = min(bottomRightRadius, maximumRadius)
        let bottomLeft = min(bottomLeftRadius, maximumRadius)
        let path = UIBezierPath()

        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight), radius: topRight,
            startAngle: -.pi / 2, endAngle: 0, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight), radius: bottomRight,
            startAngle: 0, endAngle: .pi / 2, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft), radius: bottomLeft,
            startAngle: .pi / 2, endAngle: .pi, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft), radius: topLeft,
            startAngle: .pi, endAngle: .pi * 1.5, clockwise: true
        )
        path.close()
        return path
    }
}
