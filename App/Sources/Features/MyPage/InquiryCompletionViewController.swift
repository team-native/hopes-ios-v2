import UIKit

@MainActor
final class InquiryCompletionViewController: UIViewController {
    private let email: String

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        let header = makeHeader()
        let content = makeCompletionContent()
        let confirm = makeConfirmButton()
        activateConstraints(header: header, content: content, confirm: confirm)
    }

    private func makeHeader() -> UIStackView {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "inquiry-chevron-left"), for: .normal)
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("문의하기", size: 18, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255,
            blue: 43 / 255, alpha: 1))
        let header = UIStackView(arrangedSubviews: [backButton, title])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        return header
    }

    private func makeCompletionContent() -> UIStackView {
        let badge = UIView()
        badge.backgroundColor = .white
        badge.layer.cornerRadius = 44
        badge.layer.borderWidth = 1
        badge.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        badge.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.09).cgColor
        badge.layer.shadowOpacity = 1
        badge.layer.shadowRadius = 14
        badge.layer.shadowOffset = CGSize(width: 0, height: 8)

        let mailIcon = UIImageView(image: UIImage(named: "inquiry-mail"))
        mailIcon.contentMode = .scaleAspectFit
        mailIcon.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(mailIcon)

        let titleText = NSMutableAttributedString(string: "문의를 ", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        ])
        titleText.append(NSAttributedString(string: "보냈어요", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        ]))
        let doneTitle = UILabel()
        doneTitle.attributedText = titleText
        doneTitle.textAlignment = .center

        let description = AppStyle.label(
            "\(email)로 답변을 보내드릴게요.",
            size: 14,
            weight: .medium,
            color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
        )
        description.textAlignment = .center

        let content = UIStackView(arrangedSubviews: [badge, doneTitle, description])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        return content
    }

    private func makeConfirmButton() -> UIButton {
        let confirm = AppStyle.button("확인", primary: true) { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        confirm.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        confirm.layer.cornerRadius = 12
        confirm.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        confirm.heightAnchor.constraint(equalToConstant: 50).isActive = true
        confirm.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirm)
        return confirm
    }

    private func activateConstraints(
        header: UIView,
        content: UIStackView,
        confirm: UIView
    ) {
        guard let badge = content.arrangedSubviews.first,
              let mailIcon = badge.subviews.first as? UIImageView else { return }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            badge.widthAnchor.constraint(equalToConstant: 88),
            badge.heightAnchor.constraint(equalToConstant: 88),
            mailIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            mailIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            mailIcon.widthAnchor.constraint(equalToConstant: 36),
            mailIcon.heightAnchor.constraint(equalToConstant: 36),
            content.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            confirm.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirm.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirm.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            confirm.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
