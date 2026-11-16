import UIKit

@MainActor
extension SignupViewController {
    @objc func showGenerationPicker() {
        guard sheetView == nil else { return }
        pendingGeneration = generation ?? "10기"
        let overlay = makeGenerationOverlay()
        sheetView = overlay
    }

    private func makeGenerationOverlay() -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = UIColor(red: 20 / 255, green: 28 / 255, blue: 43 / 255, alpha: 0.36)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        addGenerationPickerDismissButton(to: overlay)
        addGenerationSheet(to: overlay)
        return overlay
    }

    private func addGenerationPickerDismissButton(to overlay: UIView) {
        let dismiss = UIButton(type: .custom)
        dismiss.addTarget(self, action: #selector(dismissPicker), for: .touchUpInside)
        dismiss.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(dismiss)
        NSLayoutConstraint.activate([
            dismiss.topAnchor.constraint(equalTo: overlay.topAnchor),
            dismiss.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            dismiss.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            dismiss.bottomAnchor.constraint(equalTo: overlay.bottomAnchor)
        ])
    }

    private func addGenerationSheet(to overlay: UIView) {
        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 28
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(sheet)
        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: overlay.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        content.addArrangedSubview(makeGenerationPickerHandle())
        let heading = makeLabel("기수 선택", size: 22, weight: .bold, color: Palette.ink)
        let headingParagraph = NSMutableParagraphStyle()
        headingParagraph.minimumLineHeight = 30
        headingParagraph.maximumLineHeight = 30
        heading.attributedText = NSAttributedString(string: "기수 선택", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: Palette.ink,
            .kern: -0.3,
            .paragraphStyle: headingParagraph
        ])
        heading.heightAnchor.constraint(equalToConstant: 30).isActive = true
        content.addArrangedSubview(heading)
        content.addArrangedSubview(makeGenerationOptionsStack())
        content.addArrangedSubview(makeGenerationSelectButton(overlay: overlay))
    }

    private func makeGenerationPickerHandle() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 5).isActive = true
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            handle.widthAnchor.constraint(equalToConstant: 44),
            handle.heightAnchor.constraint(equalToConstant: 5)
        ])
        return container
    }

    private func makeGenerationOptionsStack() -> UIStackView {
        let options = ["8기", "9기", "10기", "11기"]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        options.enumerated().forEach { index, option in
            let onSelect: (String) -> Void = { [weak self, weak stack] selected in
                self?.pendingGeneration = selected
                self?.updateGenerationOptions(in: stack, options: options)
            }
            let row = makeGenerationOption(option, selected: option == pendingGeneration, onSelect: onSelect)
            stack.addArrangedSubview(row)
            if index < options.count - 1 {
                let divider = UIView()
                divider.backgroundColor = Palette.line
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(divider)
            }
        }
        return stack
    }

    private func updateGenerationOptions(in stack: UIStackView?, options: [String]) {
        guard let stack else { return }
        options.enumerated().forEach { index, value in
            guard index * 2 < stack.arrangedSubviews.count,
                  let row = stack.arrangedSubviews[index * 2] as? UIStackView else { return }
            updateGenerationOption(row, title: value, selected: value == pendingGeneration)
        }
    }

    private func makeGenerationSelectButton(overlay: UIView) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("선택", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Palette.blue
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addAction(UIAction { [weak self, weak overlay] _ in
            guard let self, let pendingGeneration = self.pendingGeneration else { return }
            self.generation = pendingGeneration
            self.generationError = false
            overlay?.removeFromSuperview()
            self.sheetView = nil
            self.render()
        }, for: .touchUpInside)
        return button
    }

    private func makeGenerationOption(
        _ title: String,
        selected: Bool,
        onSelect: @escaping (String) -> Void
    ) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let label = makeLabel(title, size: 15, weight: selected ? .medium : .regular,
            color: selected ? Palette.blue : Palette.ink)
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        styleGenerationOptionTitle(label, title: title, selected: selected)
        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(makeGenerationRadio(selected: selected))
        addGenerationOptionButton(to: row, title: title, selected: selected, onSelect: onSelect)
        row.accessibilityIdentifier = "signup-generation-option-\(title)"
        return row
    }

    private func makeGenerationRadio(selected: Bool) -> UIView {
        let radio = UIView()
        radio.backgroundColor = selected ? Palette.blue : .white
        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = selected ? 0 : 1
        radio.layer.borderColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1).cgColor
        radio.widthAnchor.constraint(equalToConstant: 22).isActive = true
        radio.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let checkImage = UIImage(named: "CommunityReportRadioCheck")?.withRenderingMode(.alwaysOriginal)
        let checkmark = UIImageView(image: checkImage)
        checkmark.contentMode = .scaleAspectFit
        checkmark.isHidden = !selected
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        radio.addSubview(checkmark)
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: radio.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 14),
            checkmark.heightAnchor.constraint(equalToConstant: 14)
        ])
        return radio
    }

    private func addGenerationOptionButton(
        to row: UIStackView,
        title: String,
        selected: Bool,
        onSelect: @escaping (String) -> Void
    ) {
        let button = UIButton(type: .custom)
        button.accessibilityLabel = title
        button.accessibilityTraits = selected ? [.button, .selected] : .button
        button.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: row.topAnchor),
            button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        button.addAction(UIAction { _ in onSelect(title) }, for: .touchUpInside)
        row.accessibilityElements = [button]
    }

    private func updateGenerationOption(_ row: UIStackView, title: String, selected: Bool) {
        guard let label = row.arrangedSubviews.first as? UILabel,
              let radio = row.arrangedSubviews.last,
              let checkmark = radio.subviews.first as? UIImageView,
              let button = row.subviews.first(where: { $0 is UIButton }) as? UIButton else { return }
        styleGenerationOptionTitle(label, title: title, selected: selected)
        radio.backgroundColor = selected ? Palette.blue : .white
        radio.layer.borderWidth = selected ? 0 : 1
        checkmark.isHidden = !selected
        button.accessibilityTraits = selected ? [.button, .selected] : .button
    }

    private func styleGenerationOptionTitle(_ label: UILabel, title: String, selected: Bool) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 24
        paragraph.maximumLineHeight = 24
        label.attributedText = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: selected ? .medium : .regular),
            .foregroundColor: selected ? Palette.blue : Palette.ink,
            .kern: -0.1,
            .paragraphStyle: paragraph
        ])
    }
}
