import UIKit

@MainActor
extension SignupViewController {
    func renderCompleteStep() {
        addSpacer(16)
        let topSpacer = addFlexibleCompletionSpacer()
        addSpacer(16)

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        content.addArrangedSubview(makeSignupCompletionCheck())
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? UserProfileStore.shared.name
        content.addArrangedSubview(makeSignupCompletionTitle(name: name))
        content.addArrangedSubview(makeSignupCompletionSummary())
        contentStack.addArrangedSubview(content)

        addSpacer(16)
        let bottomSpacer = addFlexibleCompletionSpacer()
        addSpacer(16)
        topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor).isActive = true
    }

    private func makeSignupCompletionCheck() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.borderColor = Palette.line.cgColor
        container.layer.borderWidth = 1
        container.layer.cornerRadius = 48
        container.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        container.layer.shadowOpacity = 0.09
        container.layer.shadowRadius = 14
        container.layer.shadowOffset = CGSize(width: 0, height: 8)
        container.widthAnchor.constraint(equalToConstant: 96).isActive = true
        container.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let image = UIImage(named: "CommunityReportDoneCheck")?.withRenderingMode(.alwaysOriginal)
        let check = UIImageView(image: image)
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(check)
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 44),
            check.heightAnchor.constraint(equalToConstant: 44)
        ])
        return container
    }

    private func makeSignupCompletionTitle(name: String) -> UILabel {
        let text = "\(name)님, 가입이 끝났어요"
        let title = makeLabel(text, size: 22, weight: .bold, color: Palette.ink, alignment: .center)
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 30
        paragraph.maximumLineHeight = 30
        title.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: Palette.ink,
            .kern: -0.3,
            .paragraphStyle: paragraph
        ])
        return title
    }

    private func makeSignupCompletionSummary() -> UILabel {
        let department = UserProfileStore.shared.department
        let text = "\(department) · \(generation ?? "10기")로 가입했어요.\n이제 선배에게 무엇이든 물어보세요."
        let summary = makeLabel(text, size: 14, weight: .medium, color: Palette.muted, alignment: .center)
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 20
        paragraph.maximumLineHeight = 20
        summary.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: Palette.muted,
            .paragraphStyle: paragraph
        ])
        return summary
    }

    @discardableResult
    private func addFlexibleCompletionSpacer() -> UIView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        contentStack.addArrangedSubview(spacer)
        return spacer
    }
}
