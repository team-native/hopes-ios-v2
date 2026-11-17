import UIKit

@MainActor
class ChatContextPickerSheetViewController: UIViewController {
    let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)

    private let titleText: String
    private let subtitleText: String
    var sheetHeight: CGFloat
    private let sheet = UIView()
    private let dim = UIView()
    private var isDismissing = false

    init(title: String, subtitle: String, sheetHeight: CGFloat) {
        titleText = title
        subtitleText = subtitle
        self.sheetHeight = sheetHeight
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        configureBackdrop()
        configureSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.dim.alpha = 1
            self.sheet.transform = .identity
        }
    }

    func makeOptionsView() -> UIView { UIView() }

    func makeActionsView() -> UIView { UIView() }

    func dismissWithoutSaving(completion: (() -> Void)? = nil) {
        guard !isDismissing else { return }
        isDismissing = true
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
            self.dim.alpha = 0
            self.sheet.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    func makePickerAction(title: String, primary: Bool, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(primary ? .white : ink, for: .normal)
        button.backgroundColor = primary ? blue : .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = primary ? 0 : 1
        button.layer.borderColor = line.cgColor
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func configureBackdrop() {
        dim.translatesAutoresizingMaskIntoConstraints = false
        dim.backgroundColor = UIColor(red: 20 / 255, green: 28 / 255, blue: 43 / 255, alpha: 0.32)
        dim.alpha = 0
        view.addSubview(dim)
        let backdrop = UIView()
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        let dismissButton = UIButton(type: .custom)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.accessibilityLabel = "선택 창 닫기"
        dismissButton.addTarget(self, action: #selector(backdropTapped), for: .touchUpInside)
        dim.addSubview(backdrop)
        backdrop.addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: view.topAnchor),
            dim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.topAnchor.constraint(equalTo: dim.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: dim.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: dim.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: dim.bottomAnchor),
            dismissButton.topAnchor.constraint(equalTo: backdrop.topAnchor),
            dismissButton.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor)
        ])
    }

    private func configureSheet() {
        sheet.translatesAutoresizingMaskIntoConstraints = false
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 28
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.clipsToBounds = true
        sheet.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        view.addSubview(sheet)

        let content = UIStackView(arrangedSubviews: [
            makeHandle(), makeTitle(), makeSubtitle(), makeOptionsView(), makeActionsView(), makeHomeIndicator()
        ])
        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20)
        content.insetsLayoutMarginsFromSafeArea = false
        content.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(content)

        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            sheet.heightAnchor.constraint(equalToConstant: sheetHeight),
            content.topAnchor.constraint(equalTo: sheet.topAnchor),
            content.leadingAnchor.constraint(equalTo: sheet.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: sheet.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: sheet.bottomAnchor)
        ])
    }

    private func makeHandle() -> UIView {
        let container = UIView()
        let handle = UIView()
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.backgroundColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        container.addSubview(handle)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 5),
            handle.widthAnchor.constraint(equalToConstant: 44),
            handle.heightAnchor.constraint(equalToConstant: 5),
            handle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func makeTitle() -> UILabel {
        let label = UILabel()
        label.text = titleText
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = ink
        label.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return label
    }

    private func makeSubtitle() -> UILabel {
        let label = UILabel()
        label.text = subtitleText
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = secondary
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }

    private func makeHomeIndicator() -> UIView {
        let container = UIView()
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = ink
        indicator.isHidden = true
        indicator.layer.cornerRadius = 2.5
        container.addSubview(indicator)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 21),
            indicator.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 136),
            indicator.heightAnchor.constraint(equalToConstant: 5)
        ])
        return container
    }

    @objc private func backdropTapped() {
        dismissWithoutSaving()
    }
}
