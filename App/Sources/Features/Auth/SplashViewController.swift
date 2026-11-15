import UIKit

@MainActor
final class SplashViewController: UIViewController {
    private let logoMotion = UIView()
    private let logoTile = UIView()
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            window.rootViewController = WelcomeViewController()
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

        logoTile.backgroundColor = .white
        logoTile.layer.cornerRadius = 9
        logoTile.layer.borderWidth = 1
        logoTile.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        logoTile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        logoTile.layer.shadowOpacity = 0.05
        logoTile.layer.shadowRadius = 8
        logoTile.layer.shadowOffset = CGSize(width: 0, height: 4)
        logoTile.alpha = 0
        logoTile.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(logoTile)

        let logo = UIImageView(image: UIImage(named: "auth-logo-mark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logoTile.addSubview(logo)

        brandLabel.text = "hopes"
        brandLabel.font = .systemFont(ofSize: 22, weight: .bold)
        brandLabel.textColor = SplashPalette.ink
        brandLabel.textAlignment = .center
        brandLabel.alpha = 0
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(brandLabel)

        NSLayoutConstraint.activate([
            logoTile.centerXAnchor.constraint(equalTo: logoMotion.centerXAnchor),
            logoTile.topAnchor.constraint(equalTo: logoMotion.topAnchor, constant: 38),
            logoTile.widthAnchor.constraint(equalToConstant: 40),
            logoTile.heightAnchor.constraint(equalToConstant: 40),
            logo.centerXAnchor.constraint(equalTo: logoTile.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: logoTile.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 16),
            logo.heightAnchor.constraint(equalToConstant: 25),
            brandLabel.centerXAnchor.constraint(equalTo: logoMotion.centerXAnchor),
            brandLabel.topAnchor.constraint(equalTo: logoMotion.topAnchor, constant: 140),
            brandLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func configureCopy() {
        let tagline = UILabel()
        tagline.attributedText = NSAttributedString(string: "선배에게 묻는 가장 솔직한 학교 이야기", attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: SplashPalette.secondary,
            .kern: -0.1
        ])
        tagline.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tagline)

        let slogan = NSMutableAttributedString(attributedString: tagline.attributedText ?? NSAttributedString())
        slogan.addAttribute(.foregroundColor, value: SplashPalette.blue, range: NSRange(location: 0, length: 2))
        slogan.addAttribute(.foregroundColor, value: SplashPalette.blue, range: NSRange(location: 8, length: 6))
        tagline.attributedText = slogan

        let school = UILabel()
        school.text = "광주소프트웨어마이스터고"
        school.font = .systemFont(ofSize: 10)
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
            logoTile.alpha = 1
            brandLabel.alpha = 1
            return
        }

        logoTile.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        brandLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)

        UIView.animate(
            withDuration: 0.55,
            delay: 0,
            usingSpringWithDamping: 0.46,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.logoTile.alpha = 1
            self.logoTile.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        }

        UIView.animate(
            withDuration: 0.25,
            delay: 0.55,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.logoTile.transform = .identity
        }

        UIView.animate(
            withDuration: 0.24,
            delay: 0.5,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.brandLabel.alpha = 1
            self.brandLabel.transform = .identity
        }
    }
}

private enum SplashPalette {
    static let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    static let secondary = UIColor(red: 111 / 255, green: 127 / 255, blue: 153 / 255, alpha: 1)
    static let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
}
