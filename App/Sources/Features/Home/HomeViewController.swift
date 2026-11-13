import UIKit

@MainActor
final class HomeViewController: AppPageViewController {
    private let heroCard = UIView()
    private let heroClipView = UIView()
    private let heroCloud = UIImageView(image: UIImage(named: "home-cloud-soft"))
    private let heroGradient = CAGradientLayer()

    private let popularPosts = [
        ("전체", "전공 동아리 면접 후기 공유", "34"),
        ("9기", "취업 준비 언제부터 시작했어?", "21")
    ]

    private let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    private let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    private let canvas = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
    private let subtleBorder = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    private let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = canvas
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addHomeHeader()
        addHeroCard()
        addTipsSection()
        addPopularSection()
        view.accessibilityIdentifier = "home-screen"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroClipView.bounds
    }

    private func addHomeHeader() {
        let fullName = UserProfileStore.shared.name
        let displayName = fullName.count > 2 ? String(fullName.suffix(2)) : fullName
        let greeting = UIStackView(arrangedSubviews: [
            styledLabel("\(displayName)님, 반가워요", size: 22, weight: .bold, color: AppStyle.ink, lineHeight: 30, kern: -0.3),
            styledLabel("선배 답변을 더 정확하게 받는 방법이에요.", size: 14, weight: .medium, color: AppStyle.muted, lineHeight: 20)
        ])
        greeting.axis = .vertical
        greeting.spacing = 4

        let notificationButton = UIButton(type: .system)
        notificationButton.translatesAutoresizingMaskIntoConstraints = false
        notificationButton.setImage(UIImage(named: "home-notification-icon"), for: .normal)
        notificationButton.backgroundColor = .clear
        notificationButton.imageView?.contentMode = .scaleAspectFit
        notificationButton.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)
        notificationButton.accessibilityLabel = "알림"
        notificationButton.accessibilityIdentifier = "home-notifications"
        NSLayoutConstraint.activate([
            notificationButton.widthAnchor.constraint(equalToConstant: 44),
            notificationButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        let header = UIStackView(arrangedSubviews: [greeting, notificationButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addHeroCard() {
        heroCard.translatesAutoresizingMaskIntoConstraints = false
        heroCard.backgroundColor = UIColor(red: 245 / 255, green: 249 / 255, blue: 1, alpha: 1)
        heroCard.layer.cornerRadius = 24
        heroCard.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        heroCard.layer.shadowOpacity = 1
        heroCard.layer.shadowRadius = 8
        heroCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        heroClipView.translatesAutoresizingMaskIntoConstraints = false
        heroClipView.layer.cornerRadius = 24
        heroClipView.layer.borderWidth = 1
        heroClipView.layer.borderColor = subtleBorder.cgColor
        heroClipView.clipsToBounds = true
        heroCard.addSubview(heroClipView)
        heroGradient.colors = [UIColor(red: 251 / 255, green: 253 / 255, blue: 1, alpha: 1).cgColor,
                               UIColor(red: 238 / 255, green: 244 / 255, blue: 254 / 255, alpha: 1).cgColor]
        heroGradient.startPoint = CGPoint(x: 0, y: 0.5)
        heroGradient.endPoint = CGPoint(x: 1, y: 0.5)
        heroClipView.layer.insertSublayer(heroGradient, at: 0)
        contentStack.addArrangedSubview(heroCard)
        heroCard.heightAnchor.constraint(equalToConstant: 176).isActive = true
        NSLayoutConstraint.activate([
            heroClipView.topAnchor.constraint(equalTo: heroCard.topAnchor),
            heroClipView.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor),
            heroClipView.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor),
            heroClipView.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor)
        ])

        heroCloud.contentMode = .scaleAspectFit
        heroCloud.translatesAutoresizingMaskIntoConstraints = false
        heroClipView.addSubview(heroCloud)

        let title = styledLabel("궁금한 점이 있다면,\n언제든 물어보세요.", size: 22, weight: .bold, color: AppStyle.ink, lineHeight: 30, kern: -0.3)
        title.translatesAutoresizingMaskIntoConstraints = false
        let subtitle = styledLabel("선배들의 실제 경험으로 답해요.", size: 14, weight: .medium, color: AppStyle.muted, lineHeight: 20)
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.title = "채팅 시작하기"
        buttonConfiguration.baseForegroundColor = brandBlue
        buttonConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        buttonConfiguration.background.backgroundColor = softBlue
        buttonConfiguration.background.cornerRadius = 10
        button.configuration = buttonConfiguration
        button.addTarget(self, action: #selector(openChat), for: .touchUpInside)
        button.accessibilityIdentifier = "home-start-chat"

        heroClipView.addSubview(title)
        heroClipView.addSubview(subtitle)
        heroClipView.addSubview(button)
        NSLayoutConstraint.activate([
            heroCloud.widthAnchor.constraint(equalToConstant: 240),
            heroCloud.heightAnchor.constraint(equalToConstant: 126),
            heroCloud.leadingAnchor.constraint(equalTo: heroClipView.leadingAnchor, constant: 176),
            heroCloud.topAnchor.constraint(equalTo: heroClipView.topAnchor, constant: 60),
            title.leadingAnchor.constraint(equalTo: heroClipView.leadingAnchor, constant: 21),
            title.topAnchor.constraint(equalTo: heroClipView.topAnchor, constant: 23),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: heroClipView.topAnchor, constant: 91),
            button.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            button.topAnchor.constraint(equalTo: heroClipView.topAnchor, constant: 117),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func addTipsSection() {
        let header = styledLabel("질문 잘하는 방법", size: 18, weight: .medium, color: AppStyle.ink, lineHeight: 26, kern: -0.2)
        contentStack.addArrangedSubview(sectionHeaderContainer(header))

        let tips = UIStackView(arrangedSubviews: [
            makeTip(number: "1", label: "질문 전에,", text: "학과·전공을 먼저 골라요"),
            makeTip(number: "2", label: "“기숙사 어때” 보단,", text: "“1학년 기숙사 평일 루틴 알려줘”")
        ])
        tips.axis = .vertical
        tips.spacing = 10
        contentStack.addArrangedSubview(tips)
    }

    private func makeTip(number: String, label: String, text: String) -> UIView {
        let badge = numberBadge(number)
        let copy = UIStackView(arrangedSubviews: [
            styledLabel(label, size: 12, color: AppStyle.muted, lineHeight: 16),
            styledLabel(text, size: 15, weight: .medium, color: AppStyle.ink, lineHeight: 24, kern: -0.1)
        ])
        copy.axis = .vertical
        copy.spacing = 2

        let row = UIStackView(arrangedSubviews: [badge, copy])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        row.backgroundColor = .white
        row.layer.cornerRadius = 20
        row.layer.borderWidth = 1
        row.layer.borderColor = subtleBorder.cgColor
        row.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        row.layer.shadowOpacity = 1
        row.layer.shadowRadius = 8
        row.layer.shadowOffset = CGSize(width: 0, height: 4)
        return row
    }

    private func addPopularSection() {
        let title = styledLabel("커뮤니티 인기글", size: 18, weight: .medium, color: AppStyle.ink, lineHeight: 26, kern: -0.2)
        let more = UIButton(type: .system)
        more.setTitle("더보기", for: .normal)
        more.setTitleColor(brandBlue, for: .normal)
        more.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        more.addTarget(self, action: #selector(openCommunity), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [title, UIView(), more])
        header.axis = .horizontal
        header.alignment = .center
        contentStack.addArrangedSubview(sectionHeaderContainer(header))

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 10
        popularPosts.forEach { rows.addArrangedSubview(makePopularRow($0.0, title: $0.1, likes: $0.2)) }
        contentStack.addArrangedSubview(rows)
    }

    private func makePopularRow(_ cohort: String, title: String, likes: String) -> UIView {
        let badge = UILabel()
        badge.text = cohort
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 12)
        badge.textColor = brandBlue
        badge.backgroundColor = softBlue
        badge.layer.cornerRadius = 11
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.heightAnchor.constraint(equalToConstant: 24),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: cohort == "전체" ? 43 : 38)
        ])

        let titleLabel = styledLabel(title, size: 15, color: AppStyle.ink, lineHeight: 24, kern: -0.1)
        titleLabel.numberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let heart = UIImageView(image: UIImage(named: "home-like-icon"))
        heart.contentMode = .scaleAspectFit
        heart.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([heart.widthAnchor.constraint(equalToConstant: 14), heart.heightAnchor.constraint(equalToConstant: 14)])
        let likesLabel = styledLabel(likes, size: 12, color: tertiary, lineHeight: 16)
        let stats = UIStackView(arrangedSubviews: [heart, likesLabel])
        stats.axis = .horizontal
        stats.alignment = .center
        stats.spacing = 4

        let row = UIStackView(arrangedSubviews: [badge, titleLabel, stats])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        row.backgroundColor = .white
        row.layer.cornerRadius = 20
        row.layer.borderWidth = 1
        row.layer.borderColor = subtleBorder.cgColor
        row.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 0.05).cgColor
        row.layer.shadowOpacity = 1
        row.layer.shadowRadius = 8
        row.layer.shadowOffset = CGSize(width: 0, height: 4)
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCommunity)))
        row.isUserInteractionEnabled = true
        return row
    }

    private func numberBadge(_ value: String) -> UILabel {
        let badge = UILabel()
        badge.text = value
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 14, weight: .medium)
        badge.textColor = brandBlue
        badge.backgroundColor = softBlue
        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([badge.widthAnchor.constraint(equalToConstant: 28), badge.heightAnchor.constraint(equalToConstant: 28)])
        return badge
    }

    private func sectionHeaderContainer(_ content: UIView) -> UIView {
        let container = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func styledLabel(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, lineHeight: CGFloat, kern: CGFloat = 0) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern
        ])
        return label
    }

    @objc private func openChat() {
        tabBarController?.selectedIndex = 1
    }

    @objc private func openCommunity() {
        tabBarController?.selectedIndex = 2
    }

    @objc private func openNotifications() {
        navigationController?.pushViewController(NotificationsViewController(), animated: true)
    }
}
