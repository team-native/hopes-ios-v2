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
    private var popularContent: UIStackView?
    private weak var popularMoreButton: UIButton?

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

        if ProcessInfo.processInfo.arguments.contains("--home-loading") {
            let header = HomeLoadingHeaderFactory.make(borderColor: subtleBorder) { [weak self] in
                self?.openNotifications()
            }
            contentStack.addArrangedSubview(header)
            contentStack.addArrangedSubview(HomePreviewStateViews.skeletonCard(height: 120))
            contentStack.addArrangedSubview(HomePreviewStateViews.tipsCard(borderColor: subtleBorder))
            addPopularSection(isLoading: true, hasError: false)
        } else {
            let showsPopularError = ProcessInfo.processInfo.arguments.contains("--home-popular-error")
            addHomeHeader()
            addHeroCard()
            if !showsPopularError { addTipsSection() }
            addPopularSection(isLoading: false, hasError: showsPopularError)
        }
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

        let notificationButton = HomePreviewStateViews.notificationButton(borderColor: subtleBorder) { [weak self] in
            self?.openNotifications()
        }
        notificationButton.accessibilityLabel = "알림"
        notificationButton.accessibilityIdentifier = "home-notifications"
        let header = UIStackView(arrangedSubviews: [greeting, notificationButton])
        header.axis = .horizontal
        header.alignment = .center
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
        heroCloud.contentMode = .scaleAspectFit
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
        contentStack.addArrangedSubview(HomePreviewStateViews.sectionHeaderContainer(header))

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
        contentStack.addArrangedSubview(tips)
    }

    private func addPopularSection(isLoading: Bool, hasError: Bool) {
        let title = HomePreviewStateViews.label(
            "커뮤니티 인기글",
            size: isLoading || hasError ? 14 : 18,
            weight: .medium,
            color: isLoading || hasError ? AppStyle.muted : AppStyle.ink,
            lineHeight: isLoading || hasError ? 20 : 26,
            kern: isLoading || hasError ? 0 : -0.2
        )
        let more = UIButton(type: .system)
        popularMoreButton = more
        more.setTitle("더보기", for: .normal)
        more.setTitleColor(brandBlue, for: .normal)
        more.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        more.addTarget(self, action: #selector(openCommunity), for: .touchUpInside)
        more.isHidden = hasError || isLoading

        let header = UIStackView(arrangedSubviews: [title, UIView(), more])
        header.axis = .horizontal
        header.alignment = .center
        contentStack.addArrangedSubview(HomePreviewStateViews.sectionHeaderContainer(header))

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 10
        popularContent = content
        if isLoading {
            content.addArrangedSubview(HomePreviewStateViews.popularSkeleton())
        } else if hasError {
            content.addArrangedSubview(HomePreviewStateViews.popularError(tertiary: tertiary) { [weak self] in
                self?.retryPopularPosts()
            })
        } else {
            populatePopularRows(in: content)
        }
        contentStack.addArrangedSubview(content)
    }

    private func populatePopularRows(in container: UIStackView) {
        for post in popularPosts {
            let row = HomePopularRowFactory.make(
                cohort: post.0,
                title: post.1,
                likes: post.2,
                style: HomePopularRowStyle(
                    blue: brandBlue,
                    softBlue: softBlue,
                    tertiary: tertiary,
                    border: subtleBorder
                )
            ) { [weak self] in
                self?.openCommunity()
            }
            container.addArrangedSubview(row)
        }
    }

}

private extension HomeViewController {
    @objc func retryPopularPosts() {
        guard let popularContent else { return }
        popularContent.arrangedSubviews.forEach { view in
            popularContent.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        populatePopularRows(in: popularContent)
        popularMoreButton?.isHidden = false
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
