import UIKit

@MainActor
final class SplashViewController: UIViewController {
    private let markTile = UIView()
    private var didBeginTransition = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureLogo()
        configureCopy()
        configureDecoration()
        view.accessibilityIdentifier = "splash-screen"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didBeginTransition else { return }
        didBeginTransition = true
        markTile.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        UIView.animate(withDuration: 0.45, delay: 0, options: [.curveEaseOut]) {
            self.markTile.alpha = 1
            self.markTile.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            window.rootViewController = WelcomeViewController()
            window.makeKeyAndVisible()
        }
    }

    private func configureLogo() {
        markTile.backgroundColor = .white
        markTile.layer.cornerRadius = 21
        markTile.layer.borderWidth = 1
        markTile.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        markTile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        markTile.layer.shadowOpacity = 0.08
        markTile.layer.shadowRadius = 12
        markTile.layer.shadowOffset = CGSize(width: 0, height: 4)
        markTile.alpha = 0
        markTile.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markTile)

        let logo = UIImageView(image: UIImage(named: "auth-logo-mark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        markTile.addSubview(logo)

        NSLayoutConstraint.activate([
            markTile.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            markTile.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 268),
            markTile.widthAnchor.constraint(equalToConstant: 96),
            markTile.heightAnchor.constraint(equalToConstant: 96),
            logo.centerXAnchor.constraint(equalTo: markTile.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: markTile.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 48),
            logo.heightAnchor.constraint(equalToConstant: 73)
        ])
    }

    private func configureCopy() {
        let brand = UILabel()
        brand.text = "hopes"
        brand.font = .systemFont(ofSize: 18, weight: .semibold)
        brand.textColor = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        brand.textAlignment = .center
        brand.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(brand)

        let tagline = UILabel()
        tagline.text = "선배에게 묻는 가장 솔직한 학교 이야기"
        tagline.font = .systemFont(ofSize: 12)
        tagline.textAlignment = .center
        let slogan = NSMutableAttributedString(string: tagline.text ?? "")
        slogan.addAttribute(.foregroundColor, value: UIColor(red: 111 / 255, green: 127 / 255, blue: 153 / 255, alpha: 1), range: NSRange(location: 0, length: slogan.length))
        slogan.addAttribute(.foregroundColor, value: UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1), range: NSRange(location: 8, length: 6))
        tagline.attributedText = slogan
        tagline.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tagline)

        let school = UILabel()
        school.text = "광주소프트웨어마이스터고"
        school.font = .systemFont(ofSize: 10)
        school.textColor = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
        school.textAlignment = .center
        school.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(school)

        NSLayoutConstraint.activate([
            brand.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brand.topAnchor.constraint(equalTo: markTile.bottomAnchor, constant: 12),
            brand.heightAnchor.constraint(equalToConstant: 22),
            tagline.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            tagline.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            tagline.topAnchor.constraint(equalTo: brand.bottomAnchor, constant: 20),
            tagline.heightAnchor.constraint(equalToConstant: 18),
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
}
