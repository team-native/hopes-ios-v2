import UIKit

@MainActor
final class WelcomeViewController: UIViewController {
    private let contentStack = UIStackView()
    private let logoTile = UIView()
    private let logoMask = UIView()
    private let heading = UILabel()
    private let descriptionLabel = UILabel()
    private let chatPreview = WelcomeChatPreviewView()
    private let startButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private var didOpenLogin = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureCloudDecoration()
        configureContent()
        configureLogo()
        configureCopy()
        configureActions()
        view.accessibilityIdentifier = "welcome-screen"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--login-preview")
            || arguments.contains("--login-error-preview")
            || arguments.contains("--login-offline-preview")
            || arguments.contains("--login-loading-preview") {
            openLogin()
        }
    }

    private func configureCloudDecoration() {
        let cloud = UIImageView(image: UIImage(named: "auth-start-cloud"))
        cloud.contentMode = .scaleAspectFit
        cloud.isAccessibilityElement = false
        cloud.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cloud, at: 0)
        NSLayoutConstraint.activate([
            cloud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cloud.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -28),
            cloud.widthAnchor.constraint(equalToConstant: 357),
            cloud.heightAnchor.constraint(equalToConstant: 187)
        ])
    }

    private func configureContent() {
        contentStack.axis = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        let topSpacer = UIView()
        topSpacer.heightAnchor.constraint(equalToConstant: 74).isActive = true
        topSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentStack.addArrangedSubview(topSpacer)

        logoTile.translatesAutoresizingMaskIntoConstraints = false
        logoTile.widthAnchor.constraint(equalToConstant: 64).isActive = true
        logoTile.heightAnchor.constraint(equalToConstant: 64).isActive = true
        contentStack.addArrangedSubview(logoTile)
        contentStack.setCustomSpacing(18, after: logoTile)

        heading.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(heading)
        heading.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        contentStack.setCustomSpacing(18, after: heading)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(descriptionLabel)
        descriptionLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        contentStack.setCustomSpacing(24, after: descriptionLabel)

        chatPreview.translatesAutoresizingMaskIntoConstraints = false
        chatPreview.heightAnchor.constraint(equalToConstant: 190).isActive = true
        contentStack.addArrangedSubview(chatPreview)
        chatPreview.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

        let bottomSpacer = UIView()
        bottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentStack.addArrangedSubview(bottomSpacer)

        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(startButton)
        startButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        contentStack.setCustomSpacing(0, after: startButton)

        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        contentStack.addArrangedSubview(loginButton)
        loginButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 4)
        ])
    }

    private func configureLogo() {
        logoTile.backgroundColor = .white
        logoTile.layer.cornerRadius = 14
        logoTile.layer.borderWidth = 1
        logoTile.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        logoTile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        logoTile.layer.shadowOpacity = 0.05
        logoTile.layer.shadowRadius = 8
        logoTile.layer.shadowOffset = CGSize(width: 0, height: 4)
        logoTile.accessibilityLabel = "Hopes"

        logoMask.clipsToBounds = true
        logoMask.translatesAutoresizingMaskIntoConstraints = false
        logoTile.addSubview(logoMask)

        let logo = UIImageView(image: UIImage(named: "auth-start-logo-mark"))
        logo.contentMode = .scaleToFill
        logo.translatesAutoresizingMaskIntoConstraints = false
        logoMask.addSubview(logo)

        NSLayoutConstraint.activate([
            logoMask.centerXAnchor.constraint(equalTo: logoTile.centerXAnchor),
            logoMask.centerYAnchor.constraint(equalTo: logoTile.centerYAnchor),
            logoMask.widthAnchor.constraint(equalToConstant: 26),
            logoMask.heightAnchor.constraint(equalToConstant: 40),
            logo.widthAnchor.constraint(equalToConstant: 62),
            logo.heightAnchor.constraint(equalToConstant: 62),
            logo.centerXAnchor.constraint(equalTo: logoMask.centerXAnchor),
            logo.topAnchor.constraint(equalTo: logoMask.topAnchor, constant: -9)
        ])
    }

    private func configureCopy() {
        let title = NSMutableAttributedString(
            string: "선배에게 묻는\n가장 솔직한\n학교 이야기",
            attributes: [
                .font: UIFont.systemFont(ofSize: 34, weight: .semibold),
                .foregroundColor: WelcomePalette.ink,
                .paragraphStyle: paragraphStyle(lineHeight: 44),
                .kern: -0.4
            ]
        )
        title.addAttribute(.foregroundColor, value: WelcomePalette.blue, range: NSRange(location: 0, length: 2))
        title.addAttribute(.foregroundColor, value: WelcomePalette.blue, range: NSRange(location: 8, length: 7))
        heading.attributedText = title
        heading.numberOfLines = 3
        heading.adjustsFontForContentSizeCategory = true
        heading.accessibilityIdentifier = "welcome-heading"

        descriptionLabel.attributedText = NSAttributedString(
            string: "광주소프트웨어마이스터고 학교생활·전공·취업 질문에\n선배들이 남긴 경험으로 답해요.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: WelcomePalette.secondary,
                .paragraphStyle: paragraphStyle(lineHeight: 24),
                .kern: -0.1
            ]
        )
        descriptionLabel.numberOfLines = 2
        descriptionLabel.adjustsFontForContentSizeCategory = true
    }

    private func configureActions() {
        var startConfiguration = UIButton.Configuration.filled()
        startConfiguration.title = "시작하기"
        startConfiguration.baseBackgroundColor = WelcomePalette.blue
        startConfiguration.baseForegroundColor = .white
        startConfiguration.cornerStyle = .large
        startConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        startButton.configuration = startConfiguration
        startButton.accessibilityIdentifier = "welcome-start"
        startButton.addAction(UIAction { [weak self] _ in self?.openSignUp() }, for: .touchUpInside)

        let loginText = "이미 계정이 있으신가요?   로그인"
        let loginTitle = NSMutableAttributedString(
            string: loginText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: WelcomePalette.secondary
            ]
        )
        if let loginRange = loginText.range(of: "로그인") {
            let range = NSRange(loginRange, in: loginText)
            loginTitle.addAttribute(.foregroundColor, value: WelcomePalette.blue, range: range)
        }
        loginButton.setAttributedTitle(loginTitle, for: .normal)
        loginButton.accessibilityLabel = "이미 계정이 있으신가요? 로그인"
        loginButton.accessibilityIdentifier = "welcome-login"
        loginButton.addAction(UIAction { [weak self] _ in self?.openLogin() }, for: .touchUpInside)
    }

    private func openSignUp() {
        let navigation = UINavigationController(rootViewController: SignupViewController())
        navigation.setNavigationBarHidden(true, animated: false)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }

    private func openLogin() {
        guard !didOpenLogin else { return }
        didOpenLogin = true
        let navigation = UINavigationController(rootViewController: LoginViewController())
        navigation.modalPresentationStyle = .overFullScreen
        navigation.modalTransitionStyle = .coverVertical
        navigation.modalPresentationCapturesStatusBarAppearance = true
        navigation.view.backgroundColor = .clear
        navigation.view.isOpaque = false
        navigation.setNavigationBarHidden(true, animated: false)
        present(navigation, animated: true)
    }

    private func paragraphStyle(lineHeight: CGFloat) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        return paragraph
    }
}

private enum WelcomePalette {
    static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    static let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    static let border = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
}
