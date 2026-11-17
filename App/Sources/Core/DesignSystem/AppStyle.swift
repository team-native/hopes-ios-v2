import UIKit

enum AppStyle {
    static let bottomActionInset: CGFloat = 37
    static let bottomActionSafeInset: CGFloat = 65
    static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    static let muted = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    static let paleBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    static let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    static let canvas = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)

    static func sheetHandle() -> UIView {
        let container = UIView()
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalToConstant: 44),
            handle.heightAnchor.constraint(equalToConstant: 5),
            handle.topAnchor.constraint(equalTo: container.topAnchor),
            handle.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            handle.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        return container
    }

    static func label(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor = ink
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    static func button(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(primary ? .white : ink, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = primary ? blue : .white
        button.layer.cornerRadius = 14
        button.layer.borderWidth = primary ? 0 : 1
        button.layer.borderColor = line.cgColor
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        configuration.baseBackgroundColor = primary ? blue : .white
        configuration.baseForegroundColor = primary ? .white : ink
        button.configuration = configuration
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    static func card() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1
        view.layer.borderColor = line.cgColor
        return view
    }
}

@MainActor
class AppPageViewController: UIViewController {
    let contentStack = UIStackView()
    let scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.canvas
        configureScroll()
    }

    func configureScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28)
        ])
    }

    func addHeading(_ title: String, subtitle: String? = nil) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 7
        group.addArrangedSubview(AppStyle.label(title, size: 27, weight: .bold))
        if let subtitle { group.addArrangedSubview(AppStyle.label(subtitle, size: 14, color: AppStyle.muted)) }
        contentStack.addArrangedSubview(group)
    }

    func addSection(_ title: String) {
        contentStack.addArrangedSubview(AppStyle.label(title, size: 18, weight: .bold))
    }

    func addRow(
        _ title: String,
        subtitle: String? = nil,
        symbol: String = "chevron.right",
        action: @escaping () -> Void
    ) {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = AppStyle.line.cgColor
        button.contentHorizontalAlignment = .leading
        var config = UIButton.Configuration.plain()
        config.title = title
        config.subtitle = subtitle
        config.image = UIImage(systemName: symbol)
        config.imagePlacement = .trailing
        config.imagePadding = 12
        config.baseForegroundColor = AppStyle.ink
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .semibold)
            return outgoing
        }
        button.configuration = config
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: subtitle == nil ? 54 : 70).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
    }

    func push(_ controller: UIViewController) {
        navigationController?.pushViewController(controller, animated: true)
    }

    func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
