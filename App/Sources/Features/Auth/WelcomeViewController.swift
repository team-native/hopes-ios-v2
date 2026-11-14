import UIKit

@MainActor
final class WelcomeViewController: UIViewController {
    private let gradientLayer = CAGradientLayer()
    private let brandTile = UIView()
    private let brandMark = UILabel()
    private let brandName = UILabel()
    private let schoolName = UILabel()
    private let heading = UILabel()
    private let descriptionLabel = UILabel()
    private let chevrons = UIStackView()
    private let loginSheet = UIView()
    private var didOpenLogin = false
    private var isAnimatingCue = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 13 / 255, green: 107 / 255, blue: 199 / 255, alpha: 1)
        configureGradient()
        configureBrand()
        configureIntroduction()
        configureSwipeCue()
        configureLoginSheet()
        configureGestures()
        view.accessibilityIdentifier = "welcome-screen"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateSwipeCue()
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--login-preview")
            || arguments.contains("--login-error-preview")
            || arguments.contains("--login-offline-preview")
            || arguments.contains("--login-loading-preview") {
            openLogin()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chevrons.layer.removeAllAnimations()
        isAnimatingCue = false
    }

    private func configureGradient() {
        gradientLayer.colors = [
            UIColor(red: 46 / 255, green: 161 / 255, blue: 237 / 255, alpha: 1).cgColor,
            UIColor(red: 13 / 255, green: 107 / 255, blue: 199 / 255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureBrand() {
        brandTile.backgroundColor = .white
        brandTile.layer.cornerRadius = 12
        brandTile.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(brandTile)

        brandMark.text = "h"
        brandMark.font = .systemFont(ofSize: 26, weight: .bold)
        brandMark.textColor = UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1)
        brandMark.textAlignment = .center
        brandMark.translatesAutoresizingMaskIntoConstraints = false
        brandTile.addSubview(brandMark)

        brandName.text = "hopes"
        brandName.font = .systemFont(ofSize: 17, weight: .bold)
        brandName.textColor = .white
        brandName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(brandName)

        schoolName.text = "광주소프트웨어마이스터고"
        schoolName.font = .systemFont(ofSize: 11, weight: .medium)
        schoolName.textColor = UIColor(red: 217 / 255, green: 240 / 255, blue: 1, alpha: 1)
        schoolName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(schoolName)

        NSLayoutConstraint.activate([
            brandTile.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            brandTile.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            brandTile.widthAnchor.constraint(equalToConstant: 42),
            brandTile.heightAnchor.constraint(equalToConstant: 42),
            brandMark.centerXAnchor.constraint(equalTo: brandTile.centerXAnchor),
            brandMark.centerYAnchor.constraint(equalTo: brandTile.centerYAnchor),
            brandName.leadingAnchor.constraint(equalTo: brandTile.trailingAnchor, constant: 12),
            brandName.topAnchor.constraint(equalTo: brandTile.topAnchor, constant: 1),
            brandName.heightAnchor.constraint(equalToConstant: 20),
            schoolName.leadingAnchor.constraint(equalTo: brandName.leadingAnchor),
            schoolName.topAnchor.constraint(equalTo: brandName.bottomAnchor, constant: 1),
            schoolName.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    private func configureIntroduction() {
        heading.numberOfLines = 3
        heading.textColor = .white
        heading.attributedText = NSAttributedString(
            string: "선배에게 묻는\n가장 솔직한\n학교 이야기",
            attributes: [
                .font: UIFont.systemFont(ofSize: 31, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: lineStyle(height: 39)
            ]
        )
        heading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heading)

        descriptionLabel.numberOfLines = 2
        descriptionLabel.attributedText = NSAttributedString(
            string: "재학생, 신입생, 입학 희망자를 위한 AI 선배 챗봇.\n실제 선배들의 경험으로 답해드려요.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                .foregroundColor: UIColor(red: 214 / 255, green: 237 / 255, blue: 1, alpha: 1),
                .paragraphStyle: lineStyle(height: 24)
            ]
        )
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            heading.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 224),
            heading.widthAnchor.constraint(equalToConstant: 300),
            heading.heightAnchor.constraint(equalToConstant: 117),
            descriptionLabel.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 354),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 318),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configureSwipeCue() {
        let topChevron = UIImageView(image: UIImage(named: "swipe-chevron-top"))
        let bottomChevron = UIImageView(image: UIImage(named: "swipe-chevron-bottom"))
        [topChevron, bottomChevron].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 17).isActive = true
        }
        chevrons.axis = .vertical
        chevrons.alignment = .center
        chevrons.spacing = 1
        chevrons.addArrangedSubview(topChevron)
        chevrons.addArrangedSubview(bottomChevron)
        chevrons.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chevrons)

        let cueTitle = UILabel()
        cueTitle.text = "위로 스와이프하기"
        cueTitle.font = .systemFont(ofSize: 18, weight: .bold)
        cueTitle.textColor = .white
        cueTitle.textAlignment = .center
        cueTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cueTitle)

        let cueHint = UILabel()
        cueHint.text = "로그인 창을 올려 학교 이메일로 시작해요."
        cueHint.font = .systemFont(ofSize: 12)
        cueHint.textColor = UIColor(red: 221 / 255, green: 240 / 255, blue: 1, alpha: 1)
        cueHint.textAlignment = .center
        cueHint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cueHint)

        NSLayoutConstraint.activate([
            chevrons.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chevrons.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 503),
            cueTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 559),
            cueTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cueTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cueTitle.heightAnchor.constraint(equalToConstant: 22),
            cueHint.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 589),
            cueHint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cueHint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cueHint.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

}

private extension WelcomeViewController {
    private func configureLoginSheet() {
        loginSheet.backgroundColor = .white
        loginSheet.layer.cornerRadius = 28
        loginSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        loginSheet.layer.shadowColor = UIColor(red: 10 / 255, green: 31 / 255, blue: 56 / 255, alpha: 1).cgColor
        loginSheet.layer.shadowOpacity = 0.16
        loginSheet.layer.shadowRadius = 14
        loginSheet.layer.shadowOffset = CGSize(width: 0, height: -8)
        loginSheet.accessibilityIdentifier = "welcome-login-sheet"
        loginSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginSheet)

        let handle = UIView()
        handle.backgroundColor = UIColor(red: 214 / 255, green: 226 / 255, blue: 238 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        loginSheet.addSubview(handle)

        let title = UILabel()
        title.text = "로그인"
        title.font = .systemFont(ofSize: 25, weight: .bold)
        title.textColor = UIColor(red: 15 / 255, green: 23 / 255, blue: 42 / 255, alpha: 1)
        title.translatesAutoresizingMaskIntoConstraints = false
        loginSheet.addSubview(title)

        let subtitle = UILabel()
        subtitle.text = "학교 이메일로 로그인하세요."
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = UIColor(red: 113 / 255, green: 128 / 255, blue: 150 / 255, alpha: 1)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        loginSheet.addSubview(subtitle)

        NSLayoutConstraint.activate([
            loginSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loginSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loginSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loginSheet.heightAnchor.constraint(equalToConstant: 190),
            handle.topAnchor.constraint(equalTo: loginSheet.topAnchor, constant: 20),
            handle.centerXAnchor.constraint(equalTo: loginSheet.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 86),
            handle.heightAnchor.constraint(equalToConstant: 5),
            title.leadingAnchor.constraint(equalTo: loginSheet.leadingAnchor, constant: 30),
            title.topAnchor.constraint(equalTo: loginSheet.topAnchor, constant: 76),
            title.heightAnchor.constraint(equalToConstant: 32),
            subtitle.leadingAnchor.constraint(equalTo: loginSheet.leadingAnchor, constant: 32),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func configureGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openLogin))
        loginSheet.addGestureRecognizer(tap)
        loginSheet.isUserInteractionEnabled = true
    }

    @objc private func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            loginSheet.transform = CGAffineTransform(translationX: 0, y: min(translation.y, 0))
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            if translation.y < -72 || velocity < -500 {
                openLogin()
            } else {
                UIView.animate(withDuration: 0.22) { self.loginSheet.transform = .identity }
            }
        default:
            break
        }
    }

    @objc private func openLogin() {
        guard !didOpenLogin else { return }
        didOpenLogin = true
        let navigation = UINavigationController(rootViewController: LoginViewController())
        navigation.modalPresentationStyle = .fullScreen
        navigation.setNavigationBarHidden(true, animated: false)
        present(navigation, animated: true)
    }

    private func animateSwipeCue() {
        guard !isAnimatingCue else { return }
        isAnimatingCue = true
        UIView.animate(
            withDuration: 0.55,
            delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut]
        ) { [weak self] in
            self?.chevrons.transform = CGAffineTransform(translationX: 0, y: -4)
        }
    }

    private func lineStyle(height: CGFloat) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = height
        paragraph.maximumLineHeight = height
        return paragraph
    }
}
