import UIKit

@MainActor
extension SignupViewController {
    func addStepper(current: Int) {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 9
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 0, trailing: 20)

        let bars = UIStackView()
        bars.axis = .horizontal
        bars.spacing = 4
        for index in 0..<3 {
            let bar = UIView()
            bar.backgroundColor = index <= current ? Palette.blue : Palette.line
            bar.layer.cornerRadius = 2
            bar.heightAnchor.constraint(equalToConstant: 3).isActive = true
            bars.addArrangedSubview(bar)
        }
        wrapper.addArrangedSubview(bars)
        let text = ["1 / 3 · 이메일 인증", "2 / 3 · 비밀번호 설정", "3 / 3 · 프로필"][current]
        wrapper.addArrangedSubview(makeLabel(text, size: 11, color: Palette.blue))
        contentStack.addArrangedSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addSpacer(16)
    }

    func addHeading(lines: [String], subtitle: String? = nil) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        let title = makeLabel(lines.joined(separator: "\n"), size: 21, weight: .bold, color: Palette.ink)
        title.numberOfLines = 0
        stack.addArrangedSubview(title)
        if let subtitle {
            let description = makeLabel(subtitle, size: 12, color: Palette.muted)
            description.numberOfLines = 0
            stack.addArrangedSubview(description)
        }
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(16)
    }

    func addField(label: String, field: UITextField, error: String? = nil, showsVisibility: Bool = false) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        group.isLayoutMarginsRelativeArrangement = true
        group.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        group.addArrangedSubview(makeLabel(label, size: 12, weight: .medium, color: Palette.muted))

        field.layer.borderColor = (error == nil ? Palette.line : Palette.error).cgColor
        if showsVisibility {
            let visibility = UIButton(type: .system)
            visibility.setImage(UIImage(systemName: field.isSecureTextEntry ? "eye" : "eye.slash"), for: .normal)
            visibility.tintColor = Palette.muted
            visibility.addAction(UIAction { [weak field] _ in
                field?.isSecureTextEntry.toggle()
                visibility.setImage(UIImage(systemName: field?.isSecureTextEntry == true ? "eye" : "eye.slash"),
                    for: .normal)
            }, for: .touchUpInside)
            visibility.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
            field.rightView = visibility
            field.rightViewMode = .always
        }
        group.addArrangedSubview(field)
        if let error { group.addArrangedSubview(makeInlineError(error)) }
        contentStack.addArrangedSubview(group)
        group.translatesAutoresizingMaskIntoConstraints = false
    }

    func addLabeledControl(label: String, control: UIButton, error: String? = nil) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        group.isLayoutMarginsRelativeArrangement = true
        group.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        group.addArrangedSubview(makeLabel(label, size: 12, weight: .medium, color: Palette.muted))
        group.addArrangedSubview(control)
        if let error { group.addArrangedSubview(makeInlineError(error)) }
        contentStack.addArrangedSubview(group)
        group.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(14)
    }

    func makeInlineError(_ text: String) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = Palette.error
        icon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 12).isActive = true
        row.addArrangedSubview(icon)
        row.addArrangedSubview(makeLabel(text, size: 11, color: Palette.error))
        row.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return row
    }

    func addInlineError(_ text: String) {
        let row = makeInlineError(text)
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 20, bottom: 0, trailing: 20)
        contentStack.addArrangedSubview(row)
    }

    func makeLabel(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = 0
        return label
    }

    func addSpacer(_ height: CGFloat) {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    func dropdownConfiguration(title: String, error: Bool) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = title == "기수 선택" ? Palette.placeholder : Palette.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        config.background.backgroundColor = .white
        config.background.strokeColor = error ? Palette.error : Palette.line
        config.background.strokeWidth = 1
        config.background.cornerRadius = 12
        return config
    }

    func checkboxConfiguration() -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: termsAccepted ? "checkmark.square.fill" : "square")
        config.title = "서비스 이용약관 및 개인정보 처리방침 동의 (필수)"
        config.imagePadding = 6
        config.contentInsets = .zero
        config.baseForegroundColor = Palette.muted
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 11)
            return outgoing
        }
        return config
    }

}
