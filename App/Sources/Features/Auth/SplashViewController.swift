import UIKit

@MainActor
final class SplashViewController: UIViewController {
    private let logoMotion = UIView()
    private let logoMarkView = SplashLogoDrawView()
    private let brandLabel = UILabel()
    private var didBeginTransition = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureLogoMotion()
        configureCopy()
        configureDecoration()
        view.accessibilityIdentifier = "splash-screen"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didBeginTransition else { return }
        didBeginTransition = true
        animateLogo()
        guard !ProcessInfo.processInfo.arguments.contains("--splash-preview") else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) { [weak self] in
            guard let window = self?.view.window else { return }
            if AccessTokenStore.shared.hasToken {
                window.rootViewController = AppTabBarController()
                Task { await AuthAPI.syncProfile() }
            } else {
                window.rootViewController = WelcomeViewController()
            }
            window.makeKeyAndVisible()
        }
    }

    private func configureLogoMotion() {
        logoMotion.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoMotion)
        NSLayoutConstraint.activate([
            logoMotion.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoMotion.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -18),
            logoMotion.widthAnchor.constraint(equalToConstant: 180),
            logoMotion.heightAnchor.constraint(equalToConstant: 180)
        ])

        configureLogoElements()
        configureLogoConstraints()
    }

    private func configureLogoElements() {
        logoMarkView.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(logoMarkView)

        brandLabel.text = "hopes"
        brandLabel.font = .systemFont(ofSize: 22, weight: .bold)
        brandLabel.textColor = SplashPalette.ink
        brandLabel.textAlignment = .center
        brandLabel.alpha = 0
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(brandLabel)
    }

    private func configureLogoConstraints() {
        NSLayoutConstraint.activate([
            logoMarkView.centerXAnchor.constraint(equalTo: logoMotion.centerXAnchor),
            logoMarkView.topAnchor.constraint(equalTo: logoMotion.topAnchor),
            logoMarkView.widthAnchor.constraint(equalToConstant: 80),
            logoMarkView.heightAnchor.constraint(equalToConstant: 122),
            brandLabel.centerXAnchor.constraint(equalTo: logoMotion.centerXAnchor),
            brandLabel.topAnchor.constraint(equalTo: logoMotion.topAnchor, constant: 128),
            brandLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func configureCopy() {
        let tagline = UILabel()
        tagline.attributedText = NSAttributedString(string: "선배에게 묻는 가장 솔직한 학교 이야기", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: SplashPalette.secondary,
            .kern: 0,
            .paragraphStyle: Self.singleLineParagraphStyle(lineHeight: 20)
        ])
        tagline.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tagline)

        let slogan = NSMutableAttributedString(attributedString: tagline.attributedText ?? NSAttributedString())
        slogan.addAttribute(.foregroundColor, value: SplashPalette.blue, range: NSRange(location: 0, length: 2))
        slogan.addAttribute(.foregroundColor, value: SplashPalette.blue, range: NSRange(location: 8, length: 6))
        tagline.attributedText = slogan

        let school = UILabel()
        school.text = "광주소프트웨어마이스터고"
        school.font = .systemFont(ofSize: 12)
        school.textColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        school.textAlignment = .center
        school.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(school)

        NSLayoutConstraint.activate([
            tagline.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tagline.topAnchor.constraint(equalTo: logoMotion.bottomAnchor, constant: 16),
            tagline.heightAnchor.constraint(equalToConstant: 20),
            school.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            school.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 751),
            school.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func configureDecoration() {
        let cloud = UIImageView(image: UIImage(named: "auth-cloud-decor"))
        cloud.contentMode = .scaleAspectFit
        cloud.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cloud, at: 0)
        NSLayoutConstraint.activate([
            cloud.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 52),
            cloud.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 597),
            cloud.widthAnchor.constraint(equalToConstant: 357),
            cloud.heightAnchor.constraint(equalToConstant: 187)
        ])
    }

    private func animateLogo() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            logoMarkView.showImmediately()
            brandLabel.alpha = 1
            return
        }

        brandLabel.transform = CGAffineTransform(translationX: 0, y: 6)
        logoMarkView.animateDrawing()

        UIView.animate(
            withDuration: 0.24,
            delay: 0.82,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.brandLabel.alpha = 1
            self.brandLabel.transform = .identity
        }
    }

    private static func singleLineParagraphStyle(lineHeight: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        return style
    }
}

private enum SplashPalette {
    static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    static let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
}
