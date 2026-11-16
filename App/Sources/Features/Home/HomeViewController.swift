import UIKit

@MainActor
final class HomeViewController: AppPageViewController {
    private let heroCard = UIView()
    private let heroClipView = UIView()
    private let heroCloud = UIImageView(image: UIImage(named: "home-cloud-soft"))
    private let heroGradient = CAGradientLayer()

    var popularItems: [HomePopularItem] = HomePopularItem.samples
    let popularSection = UIStackView()
    weak var tipsSection: UIView?
    var popularTask: Task<Void, Never>?

    let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    let canvas = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
    let subtleBorder = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)

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

        if ProcessInfo.processInfo.arguments.contains("--home-loading") {
            let header = HomeLoadingHeaderFactory.make { [weak self] in
                self?.openNotifications()
            }
            contentStack.addArrangedSubview(header)
            contentStack.addArrangedSubview(HomePreviewStateViews.skeletonCard(height: 120))
            contentStack.addArrangedSubview(HomePreviewStateViews.tipsCard(borderColor: subtleBorder))
            installPopularSection()
            renderPopular(.loading)
        } else {
            addHomeHeader()
            addHeroCard()
            addTipsSection()
            installPopularSection()
            let showsPopularError = ProcessInfo.processInfo.arguments.contains("--home-popular-error")
            renderPopular(showsPopularError ? .failed : .loaded)
        }
        view.accessibilityIdentifier = "home-screen"
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appWillEnterForeground() {
        guard viewIfLoaded?.window != nil else { return }
        loadPopularPosts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let arguments = ProcessInfo.processInfo.arguments
        guard !arguments.contains("--home-loading"), !arguments.contains("--home-popular-error") else { return }
        loadPopularPosts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroClipView.bounds
    }

    private func addHomeHeader() {
        let fullName = UserProfileStore.shared.name
        let displayName = Self.greetingName(for: fullName)
        let greeting = UIStackView(arrangedSubviews: [
            HomePreviewStateViews.label(
                "\(displayName)님, 반가워요",
                size: 22,
                weight: .bold,
                color: AppStyle.ink,
                lineHeight: 30,
                kern: -0.3
            ),
            HomePreviewStateViews.label(
                "선배 답변을 더 정확하게 받는 방법이에요.",
                size: 14,
                weight: .medium,
                color: AppStyle.muted,
                lineHeight: 20
            )
        ])
        greeting.axis = .vertical
        greeting.spacing = 4
        greeting.isLayoutMarginsRelativeArrangement = true
        greeting.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)

        let notificationButton = HomePreviewStateViews.notificationButton { [weak self] in
            self?.openNotifications()
        }
        notificationButton.accessibilityLabel = "알림"
        notificationButton.accessibilityIdentifier = "home-notifications"
        let header = UIStackView(arrangedSubviews: [greeting, notificationButton])
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addHeroCard() {
        HomeHeroFactory.configureSurface(
            card: heroCard,
            clipView: heroClipView,
            gradient: heroGradient,
            borderColor: subtleBorder
        )
        contentStack.addArrangedSubview(heroCard)
        addHeroCardContent()
    }

    private func addHeroCardContent() {
        heroCloud.contentMode = .scaleToFill
        heroCloud.translatesAutoresizingMaskIntoConstraints = false
        heroClipView.addSubview(heroCloud)

        let title = HomePreviewStateViews.label(
            "궁금한 점이 있다면,\n언제든 물어보세요.",
            size: 22,
            weight: .bold,
            color: AppStyle.ink,
            lineHeight: 30,
            kern: -0.3
        )
        title.translatesAutoresizingMaskIntoConstraints = false
        let subtitle = HomePreviewStateViews.label(
            "선배들의 실제 경험으로 답해요.",
            size: 14,
            weight: .medium,
            color: AppStyle.muted,
            lineHeight: 20
        )
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let button = HomeHeroFactory.chatStartButton(blue: brandBlue, softBlue: softBlue) { [weak self] in
            self?.openChat()
        }
        button.translatesAutoresizingMaskIntoConstraints = false

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
        let header = HomePreviewStateViews.label(
            "질문 잘하는 방법",
            size: 18,
            weight: .medium,
            color: AppStyle.ink,
            lineHeight: 26,
            kern: -0.2
        )
        let headerView = sectionHeader(title: header)

        let tips = UIStackView(arrangedSubviews: [
            HomeTipRowFactory.make(
                number: "1",
                caption: "질문 전에,",
                text: "학과·전공을 먼저 골라요",
                blue: brandBlue,
                softBlue: softBlue
            ),
            HomeTipRowFactory.make(
                number: "2",
                caption: "“기숙사 어때” 보단,",
                text: "“1학년 기숙사 평일 루틴 알려줘”",
                blue: brandBlue,
                softBlue: softBlue
            )
        ])
        tips.axis = .vertical
        tips.spacing = 10
        let section = UIStackView(arrangedSubviews: [headerView, tips])
        section.axis = .vertical
        section.spacing = 16
        tipsSection = section
        contentStack.addArrangedSubview(section)
    }

    func sectionHeader(title: UILabel, moreButton: UIButton? = nil) -> UIView {
        let header = UIView()
        title.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(title)
        header.heightAnchor.constraint(equalToConstant: 42).isActive = true

        if let moreButton {
            moreButton.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(moreButton)
            NSLayoutConstraint.activate([
                title.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
                title.leadingAnchor.constraint(equalTo: header.leadingAnchor),
                title.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor),
                title.heightAnchor.constraint(equalToConstant: 26),
                moreButton.topAnchor.constraint(equalTo: header.topAnchor, constant: 19),
                moreButton.trailingAnchor.constraint(equalTo: header.trailingAnchor),
                moreButton.widthAnchor.constraint(equalToConstant: 39),
                moreButton.heightAnchor.constraint(equalToConstant: 20)
            ])
        } else {
            NSLayoutConstraint.activate([
                title.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
                title.leadingAnchor.constraint(equalTo: header.leadingAnchor),
                title.trailingAnchor.constraint(equalTo: header.trailingAnchor),
                title.heightAnchor.constraint(equalToConstant: 26)
            ])
        }
        return header
    }

}

extension HomeViewController {
    static func greetingName(for fullName: String) -> String {
        let name = fullName.trimmingCharacters(in: .whitespaces)
        let isHangul = name.unicodeScalars.allSatisfy { (0xAC00...0xD7A3).contains($0.value) }
        let isKoreanFullName = name.count == 3 && isHangul
        return isKoreanFullName ? String(name.dropFirst()) : name
    }

    @objc func openChat() {
        tabBarController?.selectedIndex = 1
    }

    @objc func openCommunity() {
        tabBarController?.selectedIndex = 2
    }

    @objc func openNotifications() {
        navigationController?.pushViewController(NotificationsViewController(), animated: true)
    }
}
