import UIKit

@MainActor
final class MajorPickerViewController: UIViewController {
    var onComplete: ((String?) -> Void)?

    private let options = ["iOS", "Android", "Frontend", "Backend", "AI", "IoT", "DevOps", "Design", "기타"]
    private let optionsStack = UIStackView()
    private var buttons: [String: UIButton] = [:]
    private var selectedMajor: String?

    init(selectedMajor: String?) {
        self.selectedMajor = selectedMajor
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        configureOptionsStack()
        updateSelection()

        let title = AppStyle.label("전공 선택", size: 22, weight: .bold)
        let subtitle = AppStyle.label("관심 전공을 고르면 그에 맞는 질문을 추천해 드려요.", size: 14, color: AppStyle.muted)
        let actions = makeActions()
        let stack = makeContentStack(title: title, subtitle: subtitle, actions: actions)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureOptionsStack() {
        optionsStack.axis = .vertical
        optionsStack.spacing = 8
        for start in stride(from: 0, to: options.count, by: 3) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            for option in options[start..<min(start + 3, options.count)] {
                let button = UIButton(type: .system)
                button.setTitle(option, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
                button.layer.cornerRadius = 18
                button.layer.borderWidth = 1
                button.heightAnchor.constraint(equalToConstant: 38).isActive = true
                button.addAction(UIAction { [weak self] _ in
                    self?.selectedMajor = option
                    self?.updateSelection()
                }, for: .touchUpInside)
                buttons[option] = button
                row.addArrangedSubview(button)
            }
            while row.arrangedSubviews.count < 3 { row.addArrangedSubview(UIView()) }
            optionsStack.addArrangedSubview(row)
        }
    }

    private func makeActions() -> UIStackView {
        let clear = UIButton(type: .system)
        clear.setTitle("선택 해제", for: .normal)
        clear.setTitleColor(AppStyle.ink, for: .normal)
        clear.backgroundColor = .white
        clear.layer.cornerRadius = 12
        clear.layer.borderWidth = 1
        clear.layer.borderColor = AppStyle.line.cgColor
        clear.heightAnchor.constraint(equalToConstant: 48).isActive = true
        clear.addAction(UIAction { [weak self] _ in
            self?.selectedMajor = nil
            self?.updateSelection()
        }, for: .touchUpInside)

        let done = AppStyle.button("완료", primary: true) { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true) { [weak self] in self?.onComplete?(self?.selectedMajor) }
        }
        let actions = UIStackView(arrangedSubviews: [clear, done])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually
        return actions
    }

    private func makeContentStack(title: UILabel, subtitle: UILabel, actions: UIStackView) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [title, subtitle, optionsStack, actions])
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func updateSelection() {
        buttons.forEach { option, button in
            let selected = option == selectedMajor
            button.backgroundColor = selected ? AppStyle.paleBlue : .white
            button.setTitleColor(selected ? AppStyle.blue : AppStyle.ink, for: .normal)
            button.layer.borderColor = (selected ? AppStyle.blue : AppStyle.line).cgColor
        }
    }
}
