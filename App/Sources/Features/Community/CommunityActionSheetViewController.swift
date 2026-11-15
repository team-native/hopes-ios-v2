import UIKit

@MainActor
struct CommunityActionSheetAction {
    let title: String
    let iconName: String
    let titleColor: UIColor
    let accessibilityIdentifier: String
    let handler: () -> Void
}

@MainActor
final class CommunityActionSheetViewController: UIViewController, UIGestureRecognizerDelegate {
    private let actions: [CommunityActionSheetAction]
    private let accessibilityIdentifier: String
    private let closeAccessibilityIdentifier: String
    private let dimView = UIView()
    private let sheetView = UIView()
    private var sheetBottomConstraint: NSLayoutConstraint?

    init(
        actions: [CommunityActionSheetAction],
        accessibilityIdentifier: String,
        closeAccessibilityIdentifier: String = "community-action-sheet-close"
    ) {
        self.actions = actions
        self.accessibilityIdentifier = accessibilityIdentifier
        self.closeAccessibilityIdentifier = closeAccessibilityIdentifier
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.accessibilityIdentifier = accessibilityIdentifier
        configureDimView()
        configureSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sheetBottomConstraint?.constant = -6
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

        let rows = UIStackView()
        rows.axis = .vertical
        for (index, action) in actions.enumerated() {
            rows.addArrangedSubview(makeActionRow(action))
            if index < actions.count - 1 { rows.addArrangedSubview(makeDivider()) }
        }

        let close = UIButton(type: .system)
        close.setTitle("닫기", for: .normal)
        close.setTitleColor(primaryTextColor, for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        close.backgroundColor = .white
        close.layer.cornerRadius = 12
        close.layer.borderWidth = 1
        close.layer.borderColor = subtleBorderColor.cgColor
        close.accessibilityIdentifier = closeAccessibilityIdentifier
        close.addAction(UIAction { [weak self] _ in self?.dismissSheet() }, for: .touchUpInside)
        close.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let indicator = makeHomeIndicator()
        let content = UIStackView(arrangedSubviews: [handle, rows, close, indicator])
        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalToConstant: 44),
            handle.heightAnchor.constraint(equalToConstant: 5),
            indicator.heightAnchor.constraint(equalToConstant: 21)
        ])
        return content
    }

    private func makeActionRow(_ action: CommunityActionSheetAction) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(named: action.iconName)?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        let label = AppStyle.label(action.title, size: 15, color: action.titleColor)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        button.addSubview(icon)
        button.addSubview(label)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 52),
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor)
        ])
        button.accessibilityLabel = action.title
        button.accessibilityIdentifier = action.accessibilityIdentifier
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.dismissSheet(completion: action.handler)
        }, for: .touchUpInside)
        return button
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = subtleBorderColor
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private var primaryTextColor: UIColor {
        UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    }

    private var subtleBorderColor: UIColor {
        UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    }

    private func makeHomeIndicator() -> UIView {
        let container = UIView()
        let indicator = UIView()
        indicator.backgroundColor = primaryTextColor
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
        touch.view?.isDescendant(of: sheetView) != true
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
            sheetBottomConstraint?.constant = -6 + max(0, translation)
        case .ended, .cancelled:
            if translation > 80 {
                dismissSheet()
            } else {
                sheetBottomConstraint?.constant = -6
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.2) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
}
