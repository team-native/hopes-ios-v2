import UIKit

@MainActor
final class WelcomeViewController: UIViewController {
    private let gradientLayer = CAGradientLayer()
    private let loginSheet = UIView()
    private var didOpenLogin = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    override var prefersHomeIndicatorAutoHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0x0D6BC7)
        configureBackground()
        configureBrand()
        configureHero()
        configureSwipeCue()
        configureLoginPeek()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        view.addGestureRecognizer(pan)
        view.accessibilityIdentifier = "welcome-screen"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ProcessInfo.processInfo.arguments.contains("--login-preview") {
            openLogin()
        }
    }

    private func configureBackground() {
        gradientLayer.colors = [
            UIColor(hex: 0x2EA1ED).cgColor,
            UIColor(hex: 0x0D6BC7).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureBrand() {
        let mark = UIView()
        mark.backgroundColor = .white
        mark.layer.cornerRadius = 12
        mark.layer.shadowColor = UIColor.black.withAlphaComponent(0.09).cgColor
        mark.layer.shadowOpacity = 1
        mark.layer.shadowRadius = 11
        mark.layer.shadowOffset = CGSize(width: 0, height: 8)

        let monogram = UILabel()
        monogram.text = "h"
        monogram.textAlignment = .center
        monogram.textColor = UIColor(hex: 0x0D8AE5)
        monogram.font = .systemFont(ofSize: 26, weight: .bold)
        monogram.translatesAutoresizingMaskIntoConstraints = false
        mark.addSubview(monogram)
        NSLayoutConstraint.activate([
            monogram.leadingAnchor.constraint(equalTo: mark.leadingAnchor),
            monogram.trailingAnchor.constraint(equalTo: mark.trailingAnchor),
            monogram.topAnchor.constraint(equalTo: mark.topAnchor, constant: 2),
            monogram.bottomAnchor.constraint(equalTo: mark.bottomAnchor, constant: -2)
        ])

        let wordmark = UILabel()
        wordmark.text = "hopes"
        wordmark.font = .systemFont(ofSize: 17, weight: .bold)
        wordmark.textColor = .white

        let school = UILabel()
        school.text = "광주소프트웨어마이스터고"
        school.font = .systemFont(ofSize: 11, weight: .medium)
        school.textColor = UIColor(hex: 0xD9F0FF)

        let nameStack = UIStackView(arrangedSubviews: [wordmark, school])
        nameStack.axis = .vertical
        nameStack.spacing = 0
        nameStack.alignment = .leading

        let brand = UIStackView(arrangedSubviews: [mark, nameStack])
        brand.axis = .horizontal
        brand.alignment = .center
        brand.spacing = 12
        brand.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(brand)

        NSLayoutConstraint.activate([
            mark.widthAnchor.constraint(equalToConstant: 42),
            mark.heightAnchor.constraint(equalToConstant: 42),
            brand.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            brand.topAnchor.constraint(equalTo: view.topAnchor, constant: 76)
        ])
    }

    private func configureHero() {
        let hero = UILabel()
        hero.numberOfLines = 3
        hero.text = "선배에게 묻는\n가장 솔직한\n학교 이야기"
        hero.font = .systemFont(ofSize: 31, weight: .bold)
        hero.textColor = .white
        hero.adjustsFontSizeToFitWidth = true
        hero.minimumScaleFactor = 0.9
        hero.accessibilityIdentifier = "welcome-hero"
        hero.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hero)

        let description = UILabel()
        description.numberOfLines = 2
        description.text = "재학생, 신입생, 입학 희망자를 위한 AI 선배 챗봇.\n실제 선배들의 경험으로 답해드려요."
        description.font = interFont(size: 15, bold: false)
        description.textColor = UIColor(hex: 0xD6EDFF)
        description.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(description)

        NSLayoutConstraint.activate([
            hero.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            hero.topAnchor.constraint(equalTo: view.topAnchor, constant: 286),
            hero.widthAnchor.constraint(equalToConstant: 300),
            hero.heightAnchor.constraint(equalToConstant: 117),
            description.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            description.topAnchor.constraint(equalTo: view.topAnchor, constant: 416),
            description.widthAnchor.constraint(equalToConstant: 338),
            description.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configureSwipeCue() {
        let arrows = UIStackView()
        arrows.axis = .vertical
        arrows.alignment = .center
        arrows.spacing = -1
        arrows.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arrows)

        ["swipe-chevron-top", "swipe-chevron-bottom"].forEach { name in
            let imageView = UIImageView(image: UIImage(named: name))
            imageView.contentMode = .scaleToFill
            imageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 17).isActive = true
            arrows.addArrangedSubview(imageView)
        }

        let title = UILabel()
        title.text = "위로 스와이프하기"
        title.textAlignment = .center
        title.font = interFont(size: 18, bold: true)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        let hint = UILabel()
        hint.text = "로그인 창을 올려 학교 이메일로 시작해요."
        hint.textAlignment = .center
        hint.font = interFont(size: 12, bold: false)
        hint.textColor = UIColor(hex: 0xDDF0FF)
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        NSLayoutConstraint.activate([
            arrows.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrows.topAnchor.constraint(equalTo: view.topAnchor, constant: 565),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            title.topAnchor.constraint(equalTo: view.topAnchor, constant: 621),
            title.heightAnchor.constraint(equalToConstant: 22),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hint.topAnchor.constraint(equalTo: view.topAnchor, constant: 651),
            hint.heightAnchor.constraint(equalToConstant: 15)
        ])
    }

    private func configureLoginPeek() {
        loginSheet.backgroundColor = .white
        loginSheet.layer.cornerRadius = 28
        loginSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        loginSheet.layer.shadowColor = UIColor(red: 10 / 255, green: 31 / 255, blue: 56 / 255, alpha: 1).cgColor
        loginSheet.layer.shadowOpacity = 0.16
        loginSheet.layer.shadowRadius = 28
        loginSheet.layer.shadowOffset = CGSize(width: 0, height: -12)
        loginSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginSheet)

        let handle = UIView()
        handle.backgroundColor = UIColor(hex: 0xD6E2EE)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        loginSheet.addSubview(handle)

        let heading = UILabel()
        heading.text = "로그인"
        heading.font = interFont(size: 25, bold: true)
        heading.textColor = UIColor(hex: 0x0F172A)
        heading.translatesAutoresizingMaskIntoConstraints = false
        loginSheet.addSubview(heading)

        let subtitle = UILabel()
        subtitle.text = "학교 이메일로 로그인하세요."
        subtitle.font = interFont(size: 12, bold: false)
        subtitle.textColor = UIColor(hex: 0x718096)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        loginSheet.addSubview(subtitle)

        NSLayoutConstraint.activate([
            loginSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loginSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loginSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loginSheet.heightAnchor.constraint(equalToConstant: 190),
            handle.centerXAnchor.constraint(equalTo: loginSheet.centerXAnchor),
            handle.topAnchor.constraint(equalTo: loginSheet.topAnchor, constant: 20),
            handle.widthAnchor.constraint(equalToConstant: 86),
            handle.heightAnchor.constraint(equalToConstant: 5),
            heading.leadingAnchor.constraint(equalTo: loginSheet.leadingAnchor, constant: 30),
            heading.topAnchor.constraint(equalTo: loginSheet.topAnchor, constant: 78),
            subtitle.leadingAnchor.constraint(equalTo: loginSheet.leadingAnchor, constant: 32),
            subtitle.topAnchor.constraint(equalTo: loginSheet.topAnchor, constant: 118)
        ])
    }

    @objc private func handleSwipe(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .ended,
              !didOpenLogin,
              recognizer.translation(in: view).y < -40,
              view.window != nil else { return }
        openLogin()
    }

    private func openLogin() {
        guard !didOpenLogin else { return }
        didOpenLogin = true
        let navigation = UINavigationController(rootViewController: LoginViewController())
        navigation.view.backgroundColor = .clear
        navigation.view.isOpaque = false
        navigation.modalPresentationStyle = .overFullScreen
        navigation.modalPresentationCapturesStatusBarAppearance = true
        present(navigation, animated: true)
    }

    private func interFont(size: CGFloat, bold: Bool) -> UIFont {
        guard let regular = UIFont(name: "Inter-Regular", size: size) else {
            return .systemFont(ofSize: size, weight: bold ? .bold : .regular)
        }
        guard bold, let descriptor = regular.fontDescriptor.withSymbolicTraits(.traitBold) else {
            return regular
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
