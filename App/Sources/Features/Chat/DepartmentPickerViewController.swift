import UIKit

@MainActor
final class DepartmentPickerViewController: ChatContextPickerSheetViewController {
    var onComplete: ((String?) -> Void)?

    private let departments = ["소프트웨어개발과", "스마트IoT과", "인공지능과"]
    private var draftDepartment: String?
    private var optionButtons: [UIButton] = []

    init(selectedDepartment: String?) {
        draftDepartment = selectedDepartment
        super.init(title: "학과 선택", subtitle: "선택한 학과가 AI 답변과 추천 질문에 반영돼요.", sheetHeight: 378)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeOptionsView() -> UIView {
        let options = UIStackView()
        options.axis = .vertical
        options.spacing = 0
        for (index, department) in departments.enumerated() {
            let row = makeDepartmentRow(department)
            options.addArrangedSubview(row)
            if index < departments.count - 1 {
                let divider = UIView()
                divider.backgroundColor = line
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                options.addArrangedSubview(divider)
            }
        }
        options.heightAnchor.constraint(equalToConstant: 158).isActive = true
        updateOptionStyles()
        return options
    }

    override func makeActionsView() -> UIView {
        let clear = makePickerAction(title: "선택 해제", primary: false) { [weak self] in
            self?.completeSelection(nil)
        }
        let done = makePickerAction(title: "완료", primary: true) { [weak self] in
            self?.completeSelection(self?.draftDepartment)
        }
        let actions = UIStackView(arrangedSubviews: [clear, done])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually
        actions.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return actions
    }

    private func makeDepartmentRow(_ department: String) -> UIButton {
        let title = UILabel()
        title.text = department
        title.font = .systemFont(ofSize: 15)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let radio = UIView()
        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = 1
        let check = UIImageView(image: UIImage(named: "DepartmentPickerCheck")?.withRenderingMode(.alwaysOriginal))
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        radio.addSubview(check)
        NSLayoutConstraint.activate([
            radio.widthAnchor.constraint(equalToConstant: 22),
            radio.heightAnchor.constraint(equalToConstant: 22),
            check.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: radio.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 14),
            check.heightAnchor.constraint(equalToConstant: 14)
        ])

        let row = UIStackView(arrangedSubviews: [title, UIView(), radio])
        row.axis = .horizontal
        row.alignment = .center
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true
        row.isUserInteractionEnabled = false
        let button = UIButton(type: .custom)
        button.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.accessibilityLabel = department
        button.accessibilityIdentifier = "department-option-\(department)"
        button.addAction(UIAction { [weak self] _ in
            self?.draftDepartment = department
            self?.updateOptionStyles()
        }, for: .touchUpInside)
        optionButtons.append(button)
        return button
    }

    private func updateOptionStyles() {
        for (index, button) in optionButtons.enumerated() {
            let selected = departments[index] == draftDepartment
            guard let row = button.subviews.first as? UIStackView,
                  let title = row.arrangedSubviews.first as? UILabel,
                  let radio = row.arrangedSubviews.last,
                  let check = radio.subviews.first as? UIImageView else { continue }
            title.font = .systemFont(ofSize: 15, weight: selected ? .medium : .regular)
            title.textColor = selected ? blue : ink
            radio.backgroundColor = selected ? blue : .white
            radio.layer.borderColor = (selected ? blue : line).cgColor
            check.isHidden = !selected
            button.accessibilityTraits = selected ? [.button, .selected] : [.button]
        }
    }

    private func completeSelection(_ department: String?) {
        dismissWithoutSaving { [weak self] in
            self?.onComplete?(department)
        }
    }
}
