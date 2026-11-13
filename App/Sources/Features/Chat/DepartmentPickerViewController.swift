import UIKit

@MainActor
final class DepartmentPickerViewController: UIViewController {
    var onSelect: ((String) -> Void)?
    private let selectedDepartment: String
    private let departments = ["소프트웨어개발과", "스마트IoT과", "인공지능과"]

    init(selectedDepartment: String) {
        self.selectedDepartment = selectedDepartment
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.canvas
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        let title = AppStyle.label("학과 선택", size: 22, weight: .bold)
        let subtitle = AppStyle.label("선택한 학과가 AI 답변과 추천 질문에 반영돼요.", size: 14, color: AppStyle.muted)
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 9
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 28, leading: 20, bottom: 24, trailing: 20)

        departments.forEach { department in
            let button = UIButton(type: .system)
            button.setTitle(department, for: .normal)
            button.setTitleColor(department == selectedDepartment ? AppStyle.blue : AppStyle.ink, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.contentHorizontalAlignment = .leading
            button.backgroundColor = .white
            button.layer.cornerRadius = 14
            button.layer.borderWidth = 1
            button.layer.borderColor = (department == selectedDepartment ? AppStyle.blue : AppStyle.line).cgColor
            button.heightAnchor.constraint(equalToConstant: 52).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.select(department) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }

        let cancel = UIButton(type: .system)
        cancel.setTitle("취소", for: .normal)
        cancel.setTitleColor(AppStyle.muted, for: .normal)
        cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        stack.addArrangedSubview(cancel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func select(_ department: String) {
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(department)
        }
    }
}
