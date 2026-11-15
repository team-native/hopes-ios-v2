import UIKit

@MainActor
final class CommunityCommentMenuViewController: UIViewController, UIGestureRecognizerDelegate {
    private let onEdit: () -> Void
    private let onDelete: () -> Void
    private let dimView = UIView()
    private let sheetView = UIView()
    private var sheetBottomConstraint: NSLayoutConstraint?

    init(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.onEdit = onEdit
        self.onDelete = onDelete
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.accessibilityIdentifier = "community-comment-actions-sheet"
        configureDimView()
        configureSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sheetBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    private func configureDimView() {
        dimView.backgroundColor = UIColor(red: 20 / 255, green: 28 / 255, blue: 43 / 255, alpha: 0.36)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFromBackground))
        tap.delegate = self
        dimView.addGestureRecognizer(tap)
    }

    private func configureSheet() {
        sheetView.backgroundColor = .white
        sheetView.layer.cornerRadius = 28
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        let content = makeContent()
        sheetView.addSubview(content)
        let bottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 270)
        sheetBottomConstraint = bottomConstraint
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
            content.topAnchor.constraint(equalTo: sheetView.topAnchor),
            content.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor)
        ])
        sheetView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    private func makeContent() -> UIStackView {
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false

        let rows = UIStackView(arrangedSubviews: [
            makeActionRow(title: "댓글 수정", icon: .edit, color: AppStyle.ink) { [weak self] in
                guard let self else { return }
                self.dismissSheet(completion: self.onEdit)
            },
            makeDivider(),
            makeActionRow(title: "댓글 삭제", icon: .delete,
                color: UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)) { [weak self] in
                    guard let self else { return }
                    self.dismissSheet(completion: self.onDelete)
                }
        ])
        rows.axis = .vertical
        let close = UIButton(type: .system)
        close.setTitle("닫기", for: .normal)
        close.setTitleColor(AppStyle.ink, for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        close.backgroundColor = .white
        close.layer.cornerRadius = 12
        close.layer.borderWidth = 1
        close.layer.borderColor = subtleBorderColor.cgColor
        close.accessibilityIdentifier = "community-comment-actions-close"
        close.addAction(UIAction { [weak self] _ in self?.dismissSheet() }, for: .touchUpInside)
        close.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let indicator = makeHomeIndicator()
        let content = UIStackView(arrangedSubviews: [handle, rows, close, indicator])
        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 8, trailing: 20)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalToConstant: 44),
            handle.heightAnchor.constraint(equalToConstant: 5),
            indicator.heightAnchor.constraint(equalToConstant: 21)
        ])
        return content
    }

    private func makeActionRow(
        title: String,
        icon: CommunityCommentActionIconView.Kind,
        color: UIColor,
        action: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let iconView = CommunityCommentActionIconView(kind: icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let label = AppStyle.label(title, size: 15, color: color)
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(iconView)
        button.addSubview(label)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 52),
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor)
        ])
        button.accessibilityLabel = title
        button.accessibilityIdentifier = title == "댓글 수정"
            ? "community-comment-actions-edit"
            : "community-comment-actions-delete"
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = subtleBorderColor
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private var subtleBorderColor: UIColor {
        UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    }

    private func makeHomeIndicator() -> UIView {
        let container = UIView()
        let indicator = UIView()
        indicator.backgroundColor = AppStyle.ink
        indicator.layer.cornerRadius = 2.5
        indicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 136),
            indicator.heightAnchor.constraint(equalToConstant: 5),
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view?.isDescendant(of: sheetView) != true
    }

    private func dismissSheet(completion: (() -> Void)? = nil) {
        sheetBottomConstraint?.constant = sheetView.bounds.height + 24
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.dismiss(animated: false, completion: completion)
        }
    }

    @objc private func dismissFromBackground() {
        dismissSheet()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view).y
        switch gesture.state {
        case .changed:
            sheetBottomConstraint?.constant = max(0, translation)
        case .ended, .cancelled:
            if translation > 80 {
                dismissSheet()
            } else {
                sheetBottomConstraint?.constant = 0
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.2) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
}

@MainActor
private final class CommunityCommentActionIconView: UIView {
    enum Kind: Equatable {
        case edit
        case delete
    }

    private let kind: Kind

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        isAccessibilityElement = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let path = kind == .edit ? makeEditPath() : makeDeletePath()
        let color = kind == .edit
            ? UIColor(red: 57 / 255, green: 68 / 255, blue: 90 / 255, alpha: 1)
            : UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        color.setStroke()
        path.lineWidth = 1.65
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    private func makeEditPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 11, y: 18.3333))
        path.addLine(to: CGPoint(x: 19.25, y: 18.3333))
        path.move(to: CGPoint(x: 15.125, y: 3.20833))
        path.addCurve(to: CGPoint(x: 16.5, y: 2.63879), controlPoint1: CGPoint(x: 15.4897, y: 2.84366),
            controlPoint2: CGPoint(x: 15.9843, y: 2.63879))
        path.addCurve(to: CGPoint(x: 17.2441, y: 2.78681), controlPoint1: CGPoint(x: 16.7554, y: 2.63879),
            controlPoint2: CGPoint(x: 17.0082, y: 2.68909))
        path.addCurve(to: CGPoint(x: 17.875, y: 3.20833), controlPoint1: CGPoint(x: 17.4801, y: 2.88453),
            controlPoint2: CGPoint(x: 17.6944, y: 3.02777))
        path.addCurve(to: CGPoint(x: 18.2965, y: 3.83919), controlPoint1: CGPoint(x: 18.0556, y: 3.3889),
            controlPoint2: CGPoint(x: 18.1988, y: 3.60327))
        path.addCurve(to: CGPoint(x: 18.4445, y: 4.58333), controlPoint1: CGPoint(x: 18.3942, y: 4.07511),
            controlPoint2: CGPoint(x: 18.4445, y: 4.32797))
        path.addCurve(to: CGPoint(x: 18.2965, y: 5.32748), controlPoint1: CGPoint(x: 18.4445, y: 4.83869),
            controlPoint2: CGPoint(x: 18.3942, y: 5.09156))
        path.addCurve(to: CGPoint(x: 17.875, y: 5.95833), controlPoint1: CGPoint(x: 18.1988, y: 5.5634),
            controlPoint2: CGPoint(x: 18.0556, y: 5.77777))
        path.addLine(to: CGPoint(x: 6.41667, y: 17.4167))
        path.addLine(to: CGPoint(x: 2.75, y: 18.3333))
        path.addLine(to: CGPoint(x: 3.66667, y: 14.6667))
        path.close()
        return path
    }

    private func makeDeletePath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.75, y: 5.5))
        path.addLine(to: CGPoint(x: 19.25, y: 5.5))
        path.move(to: CGPoint(x: 7.33333, y: 5.5))
        path.addLine(to: CGPoint(x: 7.33333, y: 3.66667))
        path.addLine(to: CGPoint(x: 14.6667, y: 3.66667))
        path.addLine(to: CGPoint(x: 14.6667, y: 5.5))
        path.move(to: CGPoint(x: 17.4167, y: 5.5))
        path.addLine(to: CGPoint(x: 16.5, y: 18.3333))
        path.addLine(to: CGPoint(x: 5.5, y: 18.3333))
        path.addLine(to: CGPoint(x: 4.58333, y: 5.5))
        return path
    }
}
