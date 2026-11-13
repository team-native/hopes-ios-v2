import UIKit

@MainActor
final class LoginViewController: AppPageViewController {
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let rememberButton = UIButton(type: .system)
    private var remembersLogin = true

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .white

        let logo = AppStyle.label("Hopes", size: 16, weight: .bold, color: AppStyle.blue)
        logo.textAlignment = .center
        contentStack.addArrangedSubview(logo)

        let hero = AppStyle.label("선배에게 묻는\n가장 솔직한 학교 이야기", size: 29, weight: .bold)
        hero.textAlignment = .center
        contentStack.addArrangedSubview(hero)
        let subtitle = AppStyle.label("광주소프트웨어마이스터고 선배들의 이야기", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center
        contentStack.addArrangedSubview(subtitle)

        let formCard = AppStyle.card()
        let form = UIStackView()
        form.axis = .vertical
        form.spacing = 13
        form.translatesAutoresizingMaskIntoConstraints = false
        form.addArrangedSubview(AppStyle.label("로그인", size: 20, weight: .bold))

        emailField.placeholder = "이메일"
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.autocapitalizationType = .none
        emailField.borderStyle = .roundedRect
        emailField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        form.addArrangedSubview(emailField)

        passwordField.placeholder = "비밀번호"
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password
        passwordField.borderStyle = .roundedRect
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        form.addArrangedSubview(passwordField)

        let options = UIStackView()
        options.axis = .horizontal
        options.alignment = .center
        rememberButton.contentHorizontalAlignment = .leading
        updateRememberButton()
        rememberButton.addAction(UIAction { [weak self] _ in
            self?.remembersLogin.toggle()
            self?.updateRememberButton()
        }, for: .touchUpInside)
        let spacer = UIView()
        options.addArrangedSubview(rememberButton)
        options.addArrangedSubview(spacer)
        let forgot = UIButton(type: .system)
        forgot.setTitle("비밀번호 찾기", for: .normal)
        forgot.setTitleColor(AppStyle.muted, for: .normal)
        forgot.titleLabel?.font = .systemFont(ofSize: 13)
        forgot.addAction(UIAction { [weak self] _ in
            self?.push(PasswordResetViewController())
        }, for: .touchUpInside)
        options.addArrangedSubview(forgot)
        form.addArrangedSubview(options)

        form.addArrangedSubview(AppStyle.button("로그인", primary: true) { [weak self] in
            self?.login()
        })
        formCard.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: formCard.topAnchor, constant: 20),
            form.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 18),
            form.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -18),
            form.bottomAnchor.constraint(equalTo: formCard.bottomAnchor, constant: -20)
        ])
        contentStack.addArrangedSubview(formCard)

        let signup = UIStackView()
        signup.axis = .horizontal
        signup.alignment = .center
        signup.distribution = .equalCentering
        signup.addArrangedSubview(AppStyle.label("아직 계정이 없으신가요?", size: 14, color: AppStyle.muted))
        let signupButton = UIButton(type: .system)
        signupButton.setTitle("회원가입", for: .normal)
        signupButton.setTitleColor(AppStyle.blue, for: .normal)
        signupButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        signupButton.addAction(UIAction { [weak self] _ in
            self?.push(SignupViewController())
        }, for: .touchUpInside)
        signup.addArrangedSubview(signupButton)
        contentStack.addArrangedSubview(signup)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func updateRememberButton() {
        let image = remembersLogin ? "checkmark.circle.fill" : "circle"
        rememberButton.setImage(UIImage(systemName: image), for: .normal)
        rememberButton.setTitle(" 로그인 유지", for: .normal)
        rememberButton.setTitleColor(AppStyle.muted, for: .normal)
        rememberButton.tintColor = AppStyle.blue
        rememberButton.titleLabel?.font = .systemFont(ofSize: 13)
    }

    private func login() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        guard email.contains("@"), !password.isEmpty else {
            showMessage("이메일과 비밀번호를 확인해주세요")
            return
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let window = appDelegate.window else { return }
        window.rootViewController = AppTabBarController()
        window.makeKeyAndVisible()
    }
}
