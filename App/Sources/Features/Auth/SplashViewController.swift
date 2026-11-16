import UIKit

@MainActor
final class SplashViewController: UIViewController {
    private let logoMotion = UIView()
    private let logoShadowTile = UIView()
    private let logoTile = UIView()
    private let logoImageView = UIImageView(image: UIImage(named: "auth-logo-mark"))
    private let brandLabel = UILabel()
    private var logoTileTopConstraint: NSLayoutConstraint!
    private var logoTileWidthConstraint: NSLayoutConstraint!
    private var logoTileHeightConstraint: NSLayoutConstraint!
    private var logoWidthConstraint: NSLayoutConstraint!
    private var logoHeightConstraint: NSLayoutConstraint!
    private var brandLabelTopConstraint: NSLayoutConstraint!
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

        configureLogoElements()
        configureLogoConstraints()
    }

    private func configureLogoElements() {
        logoShadowTile.backgroundColor = .clear
        logoShadowTile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        logoShadowTile.layer.shadowOpacity = 0.05
        logoShadowTile.layer.shadowRadius = 16
        logoShadowTile.layer.shadowOffset = CGSize(width: 0, height: 4)
        logoShadowTile.alpha = 0
        logoShadowTile.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(logoShadowTile)

        logoTile.backgroundColor = .white
        logoTile.layer.cornerRadius = 9
        logoTile.layer.borderWidth = 1
        logoTile.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        logoTile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        logoTile.layer.shadowOpacity = 0.03
        logoTile.layer.shadowRadius = 3
        logoTile.layer.shadowOffset = CGSize(width: 0, height: 1)
        logoTile.alpha = 0
        logoTile.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(logoTile)

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoTile.addSubview(logoImageView)

        brandLabel.text = "hopes"
        brandLabel.font = .systemFont(ofSize: 22, weight: .bold)
        brandLabel.textColor = SplashPalette.ink
        brandLabel.textAlignment = .center
        brandLabel.alpha = 0
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        logoMotion.addSubview(brandLabel)
    }

    private func configureLogoConstraints() {
        logoTileTopConstraint = logoTile.topAnchor.constraint(equalTo: logoMotion.topAnchor, constant: 38)
        logoTileWidthConstraint = logoTile.widthAnchor.constraint(equalToConstant: 40)
        logoTileHeightConstraint = logoTile.heightAnchor.constraint(equalToConstant: 40)
        logoWidthConstraint = logoImageView.widthAnchor.constraint(equalToConstant: 16)
        logoHeightConstraint = logoImageView.heightAnchor.constraint(equalToConstant: 25)
        brandLabelTopConstraint = brandLabel.topAnchor.constraint(equalTo: logoMotion.topAnchor, constant: 140)

        NSLayoutConstraint.activate([
            logoShadowTile.leadingAnchor.constraint(equalTo: logoTile.leadingAnchor),
            logoShadowTile.trailingAnchor.constraint(equalTo: logoTile.trailingAnchor),
            logoShadowTile.topAnchor.constraint(equalTo: logoTile.topAnchor),
            logoShadowTile.bottomAnchor.constraint(equalTo: logoTile.bottomAnchor),
            logoTile.centerXAnchor.constraint(equalTo: logoMotion.centerXAnchor),
            logoTileTopConstraint,
            logoTileWidthConstraint,
            logoTileHeightConstraint,
            logoImageView.centerXAnchor.constraint(equalTo: logoTile.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoTile.centerYAnchor),
            logoWidthConstraint,
            logoHeightConstraint,
            brandLabel.centerXAnchor.constraint(equalTo: logoMotion.centerXAnchor),
            brandLabelTopConstraint,
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
            setFinalLogoLayout()
            view.layoutIfNeeded()
            logoTile.alpha = 1
            logoShadowTile.alpha = 1
            brandLabel.alpha = 1
            return
        }

        logoTile.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        logoShadowTile.transform = logoTile.transform
        brandLabel.transform = CGAffineTransform(translationX: 0, y: 6)

        setFinalLogoLayout()

        UIView.animate(
            withDuration: 0.55,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.view.layoutIfNeeded()
            self.logoTile.alpha = 1
            self.logoShadowTile.alpha = 1
            self.logoTile.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            self.logoShadowTile.transform = self.logoTile.transform
        }

        UIView.animate(
            withDuration: 0.25,
            delay: 0.55,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.logoTile.transform = .identity
            self.logoShadowTile.transform = .identity
        }

        UIView.animate(
            withDuration: 0.28,
            delay: 0.52,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.25,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.brandLabel.alpha = 1
            self.brandLabel.transform = .identity
        }
    }

    private func setFinalLogoLayout() {
        logoTileTopConstraint.constant = 10
        logoTileWidthConstraint.constant = 96
        logoTileHeightConstraint.constant = 96
        logoWidthConstraint.constant = 38
        logoHeightConstraint.constant = 60
        brandLabelTopConstraint.constant = 122
        logoTile.layer.cornerRadius = 21
        logoShadowTile.layer.cornerRadius = 21
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
