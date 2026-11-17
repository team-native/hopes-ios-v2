import UIKit

@MainActor
extension SignupViewController {
    func renderCompleteStep() {

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        content.addArrangedSubview(makeSignupCompletionCheck())
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? UserProfileStore.shared.name
        content.addArrangedSubview(makeSignupCompletionTitle(name: name))
        content.addArrangedSubview(makeSignupCompletionSummary())
        content.translatesAutoresizingMaskIntoConstraints = false
        actionButton.removeFromSuperview()
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        view.addSubview(actionButton)
        let centerGuide = UILayoutGuide()
        view.addLayoutGuide(centerGuide)
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -AppStyle.bottomActionSafeInset),
            centerGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            centerGuide.bottomAnchor.constraint(equalTo: actionButton.topAnchor),
            content.centerYAnchor.constraint(equalTo: centerGuide.centerYAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
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
}
