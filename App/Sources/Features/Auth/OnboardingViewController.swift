import UIKit

@MainActor
final class OnboardingViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let chatButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .white
        configureContent()
        configureChatButton()
        view.accessibilityIdentifier = "onboarding-screen"
    }

    private func configureContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let heading = makeLabel("선배 답변을\n더 정확하게 받는 방법", size: 28, weight: .bold, color: AppStyle.ink)
        heading.attributedText = styledText(
            "선배 답변을\n더 정확하게 받는 방법",
            size: 28,
            weight: .bold,
            color: AppStyle.ink,
            lineHeight: 38,
            kern: -0.4,
            highlight: "선배"
        )
        contentStack.addArrangedSubview(heading)

        let subtitle = makeLabel(
            "질문에 학년, 관심 전공, 상황을 같이 적으면 더 현실적인 답변을 받을 수 있어요.",
            size: 15,
            color: AppStyle.muted
        )
        subtitle.attributedText = styledText(
            "질문에 학년, 관심 전공, 상황을 같이 적으면 더 현실적인 답변을 받을 수 있어요.",
            size: 15,
            weight: .regular,
            color: AppStyle.muted,
            lineHeight: 24,
            kern: -0.1
        )
        contentStack.addArrangedSubview(subtitle)
        contentStack.addArrangedSubview(makeTip(number: "1", label: "질문 전에,", text: "입학 / 전공 / 학교생활 중 카테고리를 골라요."))
        contentStack.addArrangedSubview(makeTip(number: "2", label: "“기숙사 어때” 보단,", text: "“1학년 기숙사 평일 루틴 알려줘”"))

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: chatButton.topAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func configureChatButton() {
        chatButton.translatesAutoresizingMaskIntoConstraints = false
        chatButton.setTitle("채팅 시작하기", for: .normal)
        chatButton.setTitleColor(.white, for: .normal)
        chatButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        chatButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        chatButton.layer.cornerRadius = 12
        chatButton.accessibilityIdentifier = "onboarding-start-chat"
        chatButton.addTarget(self, action: #selector(startChat), for: .touchUpInside)
        view.addSubview(chatButton)

        NSLayoutConstraint.activate([
            chatButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chatButton.heightAnchor.constraint(equalToConstant: 50),
            chatButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func makeTip(number: String, label: String, text: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)

        let badge = UILabel()
        badge.text = number
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 14, weight: .medium)
        badge.textColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        badge.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28)
        ])

        let copy = UIStackView(arrangedSubviews: [
            makeLabel(label, size: 12, color: AppStyle.muted),
            makeLabel(text, size: 15, weight: .medium, color: AppStyle.ink)
        ])
        copy.axis = .vertical
        copy.spacing = 2
        if let body = copy.arrangedSubviews.last as? UILabel {
            body.attributedText = styledText(text, size: 15, weight: .medium, color: AppStyle.ink, lineHeight: 24, kern: -0.1)
        }
        row.addArrangedSubview(badge)
        row.addArrangedSubview(copy)
        return row
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func styledText(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        lineHeight: CGFloat,
        kern: CGFloat,
        highlight: String? = nil
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern
        ])
        if let highlight, let range = text.range(of: highlight) {
            result.addAttribute(.foregroundColor, value: UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1), range: NSRange(range, in: text))
        }
        return result
    }

    @objc private func startChat() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let window = appDelegate.window else { return }
        let tabs = AppTabBarController()
        tabs.selectedIndex = 1
        window.rootViewController = tabs
        window.makeKeyAndVisible()
    }
}
