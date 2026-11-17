import UIKit

@MainActor
final class MajorPickerViewController: ChatContextPickerSheetViewController {
    var onComplete: ((String?) -> Void)?

    private let options = ["iOS", "Android", "Frontend", "Backend", "AI", "IoT", "DevOps", "Design", "기타"]
    private var selectedMajor: String?
    private var optionButtons: [String: UIButton] = [:]

    init(selectedMajor: String?) {
        self.selectedMajor = selectedMajor
        super.init(title: "전공 선택", subtitle: "관심 전공을 고르면 그에 맞는 질문을 추천해 드려요.", sheetHeight: 304)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeOptionsView() -> UIView {
        let chips = UIStackView()
        chips.axis = .vertical
        chips.alignment = .leading
        chips.spacing = 8
        let available = (view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width) - 40
        let buttons = options.map(makeMajorChip)
        let widths = buttons.map { $0.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width }
        let rows = Self.wrapRows(widths: widths, available: available, spacing: 8)
        for indices in rows {
            let row = UIStackView(arrangedSubviews: indices.map { buttons[$0] })
            row.axis = .horizontal
            row.spacing = 8
            chips.addArrangedSubview(row)
        }
        let chipsHeight = CGFloat(rows.count) * 38 + CGFloat(max(rows.count - 1, 0)) * 8
        chips.heightAnchor.constraint(equalToConstant: chipsHeight).isActive = true
        sheetHeight += chipsHeight - 84
        updateOptionStyles()
        return chips
    }

    override func makeActionsView() -> UIView {
        let clear = makePickerAction(title: "선택 해제", primary: false) { [weak self] in
            self?.completeSelection(nil)
        }
        let done = makePickerAction(title: "완료", primary: true) { [weak self] in
            self?.completeSelection(self?.selectedMajor)
        }
        let actions = UIStackView(arrangedSubviews: [clear, done])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually
        actions.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return actions
    }

    private func makeMajorChip(_ major: String) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = major
        configuration.baseForegroundColor = AppStyle.muted
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        configuration.background.backgroundColor = .white
        configuration.background.strokeColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 19
        button.configuration = configuration
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addAction(UIAction { [weak self] _ in
            self?.selectedMajor = major
            self?.updateOptionStyles()
        }, for: .touchUpInside)
        button.accessibilityIdentifier = "major-option-\(major)"
        optionButtons[major] = button
        return button
    }

    nonisolated static func wrapRows(widths: [CGFloat], available: CGFloat, spacing: CGFloat) -> [[Int]] {
        var rows: [[Int]] = []
        var current: [Int] = []
        var used: CGFloat = 0
        for (index, width) in widths.enumerated() {
            let needed = current.isEmpty ? width : used + spacing + width
            if !current.isEmpty && needed > available {
                rows.append(current)
                current = [index]
                used = width
            } else {
                current.append(index)
                used = needed
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    private func updateOptionStyles() {
        optionButtons.forEach { major, button in
            let selected = major == selectedMajor
            var configuration = button.configuration
            configuration?.baseForegroundColor = selected ? blue : AppStyle.muted
            configuration?.background.backgroundColor = selected ? softBlue : .white
            let borderColor = selected
                ? UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
                : UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
            configuration?.background.strokeColor = borderColor
            button.configuration = configuration
            button.accessibilityTraits = selected ? [.button, .selected] : [.button]
        }
    }

    private func completeSelection(_ major: String?) {
        dismissWithoutSaving { [weak self] in
            self?.onComplete?(major)
        }
    }
}
