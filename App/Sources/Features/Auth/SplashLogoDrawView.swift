import Foundation
import UIKit

@MainActor
final class SplashLogoDrawView: UIView {
    private let fillLayer = CAGradientLayer()
    private let fillMask = CAShapeLayer()
    private let outlineLayer = CAGradientLayer()
    private let outlineMask = CAShapeLayer()
    private let logo: SplashLogoVector?
    private var didConfigurePath = false

    override init(frame: CGRect) {
        logo = SplashLogoVector.load()
        super.init(frame: frame)
        accessibilityIdentifier = "splash-logo-draw"
        accessibilityLabel = "H"
        isAccessibilityElement = true
        layer.addSublayer(fillLayer)
        layer.addSublayer(outlineLayer)
        fillLayer.mask = fillMask
        outlineLayer.mask = outlineMask
        fillLayer.opacity = 0
        outlineMask.fillColor = UIColor.clear.cgColor
        outlineMask.strokeColor = UIColor.white.cgColor
        outlineMask.lineWidth = 2.5
        outlineMask.lineJoin = .round
        outlineMask.lineCap = .round
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let logo, !bounds.isEmpty else { return }

        fillLayer.frame = bounds
        outlineLayer.frame = bounds
        fillLayer.colors = logo.colors
        fillLayer.locations = logo.locations
        outlineLayer.colors = logo.colors
        outlineLayer.locations = logo.locations
        fillLayer.startPoint = logo.startPoint
        fillLayer.endPoint = logo.endPoint
        outlineLayer.startPoint = logo.startPoint
        outlineLayer.endPoint = logo.endPoint

        let sourceBounds = logo.path.boundingBoxOfPath
        let scale = min(bounds.width / sourceBounds.width, bounds.height / sourceBounds.height)
        let horizontalInset = (bounds.width - sourceBounds.width * scale) / 2
        let verticalInset = (bounds.height - sourceBounds.height * scale) / 2
        var transform = CGAffineTransform(
            a: scale,
            b: 0,
            c: 0,
            d: scale,
            tx: horizontalInset - sourceBounds.minX * scale,
            ty: verticalInset - sourceBounds.minY * scale
        )
        let path = logo.path.copy(using: &transform)
        fillMask.path = path
        outlineMask.path = path
        didConfigurePath = path != nil
    }

    func animateDrawing() {
        guard didConfigurePath, !UIAccessibility.isReduceMotionEnabled else {
            showImmediately()
            return
        }

        fillLayer.removeAllAnimations()
        outlineMask.removeAllAnimations()
        fillLayer.opacity = 0
        outlineMask.strokeEnd = 0

        let outline = CABasicAnimation(keyPath: "strokeEnd")
        outline.fromValue = 0
        outline.toValue = 1
        outline.duration = 0.82
        outline.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        outlineMask.strokeEnd = 1
        outlineMask.add(outline, forKey: "draw-outline")

        let fill = CABasicAnimation(keyPath: "opacity")
        fill.fromValue = 0
        fill.toValue = 1
        fill.beginTime = CACurrentMediaTime() + 0.72
        fill.duration = 0.22
        fill.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fillLayer.opacity = 1
        fillLayer.add(fill, forKey: "reveal-fill")
    }

    func showImmediately() {
        fillLayer.removeAllAnimations()
        outlineMask.removeAllAnimations()
        fillLayer.opacity = 1
        outlineLayer.opacity = 0
        outlineMask.strokeEnd = 1
    }
}

private struct SplashLogoVector {
    let path: CGPath
    let colors: [CGColor]
    let locations: [NSNumber]
    let startPoint: CGPoint
    let endPoint: CGPoint

    static func load() -> SplashLogoVector? {
        guard let url = Bundle.main.url(forResource: "Hopes_H_logo_vector", withExtension: "svg"),
              let data = try? Data(contentsOf: url),
              let document = SplashLogoSVGParser.parse(data: data),
              !document.stops.isEmpty,
              let path = makePath(from: document.pathData) else { return nil }

        let bounds = path.boundingBoxOfPath
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let startPoint = CGPoint(
            x: (document.gradientStart.x - bounds.minX) / bounds.width,
            y: (document.gradientStart.y - bounds.minY) / bounds.height
        )
        let endPoint = CGPoint(
            x: (document.gradientEnd.x - bounds.minX) / bounds.width,
            y: (document.gradientEnd.y - bounds.minY) / bounds.height
        )
        return SplashLogoVector(
            path: path,
            colors: document.stops.map(\.color),
            locations: document.stops.map { NSNumber(value: Double($0.location)) },
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    private static func makePath(from data: String) -> CGPath? {
        let tokens = data
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
        let path = CGMutablePath()
        var index = 0
        var command: Substring?

        while index < tokens.count {
            let token = tokens[index]
            if token == "M" || token == "L" {
                command = token
                index += 1
                guard index + 1 < tokens.count,
                      let pointX = Double(tokens[index]), let pointY = Double(tokens[index + 1]) else { return nil }
                let point = CGPoint(x: pointX, y: pointY)
                if command == "M" {
                    path.move(to: point)
                    command = "L"
                } else {
                    path.addLine(to: point)
                }
                index += 2
            } else if token == "Z" {
                path.closeSubpath()
                command = nil
                index += 1
            } else if command == "L",
                      index + 1 < tokens.count,
                      let pointX = Double(token), let pointY = Double(tokens[index + 1]) {
                path.addLine(to: CGPoint(x: pointX, y: pointY))
                index += 2
            } else {
                return nil
            }
        }
        return path.isEmpty ? nil : path
    }
}

private struct SplashLogoSVGDocument {
    struct Stop {
        let location: CGFloat
        let color: CGColor
    }

    let pathData: String
    let gradientStart: CGPoint
    let gradientEnd: CGPoint
    let stops: [Stop]
}

private final class SplashLogoSVGParser: NSObject, XMLParserDelegate {
    private var pathData: String?
    private var gradientStart = CGPoint.zero
    private var gradientEnd = CGPoint(x: 1, y: 1)
    private var stops: [SplashLogoSVGDocument.Stop] = []

    static func parse(data: Data) -> SplashLogoSVGDocument? {
        let parser = SplashLogoSVGParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        guard xml.parse(), let pathData = parser.pathData else { return nil }
        return SplashLogoSVGDocument(
            pathData: pathData,
            gradientStart: parser.gradientStart,
            gradientEnd: parser.gradientEnd,
            stops: parser.stops
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String] = [:]
    ) {
        switch elementName {
        case "linearGradient":
            gradientStart = CGPoint(x: number(attributes["x1"]), y: number(attributes["y1"]))
            gradientEnd = CGPoint(x: number(attributes["x2"]), y: number(attributes["y2"]))
        case "stop":
            guard let location = attributes["offset"].map(progress),
                  let colorValue = attributes["stop-color"],
                  let color = color(hex: colorValue) else { return }
            stops.append(.init(location: location, color: color))
        case "path":
            pathData = attributes["d"]
        default:
            break
        }
    }

    private func number(_ value: String?) -> CGFloat {
        guard let value else { return 0 }
        return CGFloat(Double(value.replacingOccurrences(of: "px", with: "")) ?? 0)
    }

    private func progress(_ value: String) -> CGFloat {
        if value.hasSuffix("%") {
            return CGFloat(Double(value.dropLast()) ?? 0) / 100
        }
        return CGFloat(Double(value) ?? 0)
    }

    private func color(hex: String) -> CGColor? {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        ).cgColor
    }
}
