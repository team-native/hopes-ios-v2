import UIKit

@MainActor
final class WelcomeViewController: UIViewController {
    private var didOpenLogin = false
    private let cloudImage = UIImageView(image: UIImage(named: "auth-cloud-decor"))

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureBrandMark()
        configureCopy()
        configureCloud()
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

    private func configureBrandMark() {
        let tile = UIView()
        tile.backgroundColor = .white
        tile.layer.cornerRadius = 18
        tile.layer.borderWidth = 1
        tile.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        tile.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        tile.layer.shadowOpacity = 0.08
        tile.layer.shadowRadius = 12
        tile.layer.shadowOffset = CGSize(width: 0, height: 4)
        tile.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tile)

        let logo = UIImageView(image: UIImage(named: "auth-logo-mark"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(logo)

        NSLayoutConstraint.activate([
            tile.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            tile.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 210),
            tile.widthAnchor.constraint(equalToConstant: 64),
            tile.heightAnchor.constraint(equalToConstant: 64),
            logo.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 26),
            logo.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func configureCopy() {
        let heading = UILabel()
        heading.numberOfLines = 3
        let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        let blue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        let title = NSMutableAttributedString(
            string: "선배에게 묻는\n가장 솔직한\n학교 이야기",
            attributes: [.font: UIFont.systemFont(ofSize: 34, weight: .semibold), .foregroundColor: ink]
        )
        title.addAttribute(.foregroundColor, value: blue, range: NSRange(location: 0, length: 2))
        title.addAttribute(.foregroundColor, value: blue, range: NSRange(location: 8, length: 6))
        heading.attributedText = title
        heading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heading)

        let body = UILabel()
        body.text = "광주소프트웨어마이스터고 학교생활·전공·취업 질문에 선배들이 남긴 경험으로 답해요."
        body.numberOfLines = 2
        body.font = .systemFont(ofSize: 15)
        body.textColor = UIColor(red: 111 / 255, green: 127 / 255, blue: 153 / 255, alpha: 1)
        body.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(body)

        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            heading.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            heading.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 290),
            heading.heightAnchor.constraint(equalToConstant: 132),
            body.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: heading.trailingAnchor),
            body.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 438),
            body.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configureCloud() {
        cloudImage.contentMode = .scaleAspectFit
        cloudImage.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cloudImage, at: 0)
        NSLayoutConstraint.activate([
            cloudImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            cloudImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 498),
            cloudImage.widthAnchor.constraint(equalToConstant: 420),
            cloudImage.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func configureActions() {
        let startButton = UIButton(type: .system)
        startButton.setTitle("시작하기", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        startButton.backgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(openLogin), for: .touchUpInside)
        startButton.accessibilityIdentifier = "welcome-start"
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

        let prompt = UILabel()
        prompt.text = "이미 계정이 있으신가요?"
        prompt.font = .systemFont(ofSize: 14)
        prompt.textColor = UIColor(red: 111 / 255, green: 127 / 255, blue: 153 / 255, alpha: 1)

        let loginButton = UIButton(type: .system)
        loginButton.setTitle("로그인", for: .normal)
        loginButton.setTitleColor(UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1), for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        loginButton.addTarget(self, action: #selector(openLogin), for: .touchUpInside)

        let link = UIStackView(arrangedSubviews: [prompt, loginButton])
        link.axis = .horizontal
        link.alignment = .center
        link.spacing = 8
        link.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(link)

        NSLayoutConstraint.activate([
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -39),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            link.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            link.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            link.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    @objc private func openLogin() {
        guard !didOpenLogin else { return }
        didOpenLogin = true
        let navigation = UINavigationController(rootViewController: LoginViewController())
        navigation.modalPresentationStyle = .fullScreen
        navigation.setNavigationBarHidden(true, animated: false)
        present(navigation, animated: true)
    }
}
