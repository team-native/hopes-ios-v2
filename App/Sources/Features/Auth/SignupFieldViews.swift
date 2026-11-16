import UIKit

@MainActor
extension SignupViewController {
    func addStepper(current: Int) {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 8

        let bars = UIStackView()
        bars.axis = .horizontal
        bars.spacing = 6
        bars.distribution = .fillEqually
        for index in 0..<3 {
            let bar = UIView()
            bar.backgroundColor = index <= current ? Palette.blue : Palette.line
            bar.layer.cornerRadius = 2
            bar.heightAnchor.constraint(equalToConstant: 4).isActive = true
            bars.addArrangedSubview(bar)
        }
        wrapper.addArrangedSubview(bars)
        let text = ["1 / 3 · 이메일 인증", "2 / 3 · 비밀번호 설정", "3 / 3 · 프로필"][current]
        wrapper.addArrangedSubview(makeLabel(text, size: 12, color: Palette.blue))
        addSpacer(8)
        contentStack.addArrangedSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.heightAnchor.constraint(equalToConstant: 28).isActive = true
        addSpacer(14)
    }

    func addHeading(lines: [String], subtitle: String? = nil, accentPrefix: String? = nil) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = subtitle == nil ? 6 : 14
        let title = makeLabel(lines.joined(separator: "\n"), size: 22, weight: .bold, color: Palette.ink)
        title.numberOfLines = 0
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.minimumLineHeight = 30
        titleParagraph.maximumLineHeight = 30
        let headingText = lines.joined(separator: "\n")
        let heading = NSMutableAttributedString(string: headingText, attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: Palette.ink,
            .paragraphStyle: titleParagraph,
            .kern: -0.3
        ])
        if let accentPrefix, let range = headingText.range(of: accentPrefix) {
            heading.addAttribute(.foregroundColor, value: Palette.blue, range: NSRange(range, in: headingText))
        }
        title.attributedText = heading
        stack.addArrangedSubview(title)
        if let subtitle {
            let description = makeLabel(subtitle, size: 14, weight: .medium, color: Palette.muted)
            description.numberOfLines = 0
            description.heightAnchor.constraint(equalToConstant: 20).isActive = true
            stack.addArrangedSubview(description)
        }
        contentStack.addArrangedSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSpacer(14)
    }

    func addField(label: String, field: UITextField, error: String? = nil, showsVisibility: Bool = false) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        let fieldLabel = makeLabel(label, size: 14, weight: .medium, color: Palette.muted)
        fieldLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        group.addArrangedSubview(fieldLabel)

        field.layer.borderColor = (error == nil ? Palette.line : Palette.error).cgColor
        field.layer.borderWidth = error == nil ? 1 : 1.5
        if showsVisibility {
            var visibilityConfig = UIButton.Configuration.plain()
            visibilityConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16)
            let visibility = UIButton(configuration: visibilityConfig)
            let eye = UIImage(named: "SignupPasswordEye")?.withRenderingMode(.alwaysOriginal)
            visibility.setImage(field.isSecureTextEntry ? eye : UIImage(systemName: "eye.slash"), for: .normal)
            visibility.tintColor = Palette.muted
            visibility.addAction(UIAction { [weak field, weak visibility] _ in
                field?.isSecureTextEntry.toggle()
                let image = field?.isSecureTextEntry == true
                    ? UIImage(named: "SignupPasswordEye")?.withRenderingMode(.alwaysOriginal)
                    : UIImage(systemName: "eye.slash")
                visibility?.setImage(image, for: .normal)
            }, for: .touchUpInside)
            visibility.frame = CGRect(x: 0, y: 0, width: 42, height: 44)
            field.rightView = visibility
            field.rightViewMode = .always
        }
        group.addArrangedSubview(field)
        if let error {
            let errorRow = makeInlineError(error)
            group.addArrangedSubview(errorRow)
            if field === emailField {
                emailErrorRow = errorRow
            }
        }
        contentStack.addArrangedSubview(group)
        group.translatesAutoresizingMaskIntoConstraints = false
    }

    func addLabeledControl(label: String, control: UIButton, error: String? = nil) {
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 6
        let controlLabel = makeLabel(label, size: 14, weight: .medium, color: Palette.muted)
        controlLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        group.addArrangedSubview(controlLabel)
        addDropdownIcon(to: control)
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
        let icon = UIImageView(image: UIImage(named: "SignupInlineAlert")?.withRenderingMode(.alwaysOriginal))
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        row.addArrangedSubview(icon)
        row.addArrangedSubview(makeLabel(text, size: 12, color: Palette.error))
        row.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return row
    }

    func addInlineError(_ text: String) {
        let row = makeInlineError(text)
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 0)
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
        config.baseForegroundColor = title == "기수 선택" ? Palette.placeholder : Palette.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 46)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15)
            outgoing.kern = -0.1
            return outgoing
        }
        config.background.backgroundColor = .white
        config.background.strokeColor = error ? Palette.error : Palette.line
        config.background.strokeWidth = error ? 1.5 : 1
        config.background.cornerRadius = 16
        return config
    }

    func checkboxConfiguration() -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = checkboxImage(checked: termsAccepted)
        config.title = "서비스 이용약관 및 개인정보 처리방침 동의 (필수)"
        config.imagePadding = 8
        config.contentInsets = .zero
        config.baseForegroundColor = Palette.muted
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12)
            return outgoing
        }
        return config
    }

    private func checkboxImage(checked: Bool) -> UIImage {
        let size = CGSize(width: 20, height: 20)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let box = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5),
                cornerRadius: 6)
            if checked {
                Palette.blue.setFill()
                box.fill()
                UIImage(named: "LoginKeepCheck")?.draw(in: CGRect(x: 3, y: 3, width: 14, height: 14))
            } else {
                UIColor.white.setFill()
                box.fill()
                UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1).setStroke()
                box.lineWidth = 1
                box.stroke()
            }
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    private func addDropdownIcon(to control: UIButton) {
        control.contentHorizontalAlignment = .leading
        guard control.viewWithTag(Self.dropdownIconTag) == nil else { return }
        let icon = UIImageView(image: UIImage(named: "SignupDropdownDown")?.withRenderingMode(.alwaysOriginal))
        icon.tag = Self.dropdownIconTag
        icon.isUserInteractionEnabled = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -16),
            icon.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private static var dropdownIconTag: Int { 7_310 }

}
