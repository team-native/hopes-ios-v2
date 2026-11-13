import UIKit

@MainActor
final class SplashViewController: UIViewController {
    private let brandStack = UIStackView()
    private var didBeginTransition = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.paleBlue

        let mark = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"))
        mark.tintColor = AppStyle.blue
        mark.contentMode = .scaleAspectFit
        mark.widthAnchor.constraint(equalToConstant: 58).isActive = true
        mark.heightAnchor.constraint(equalToConstant: 58).isActive = true

        let name = AppStyle.label("Hopes", size: 32, weight: .bold, color: AppStyle.ink)
        name.textAlignment = .center
        let tagline = AppStyle.label("선배에게 묻는 가장 솔직한 학교 이야기", size: 13, color: AppStyle.muted)
        tagline.textAlignment = .center

        brandStack.axis = .vertical
        brandStack.alignment = .center
        brandStack.spacing = 12
        brandStack.addArrangedSubview(mark)
        brandStack.addArrangedSubview(name)
        brandStack.addArrangedSubview(tagline)
        brandStack.translatesAutoresizingMaskIntoConstraints = false
        brandStack.alpha = 0
        view.addSubview(brandStack)
        NSLayoutConstraint.activate([
            brandStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brandStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didBeginTransition else { return }
        didBeginTransition = true
        brandStack.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.45, delay: 0, options: [.curveEaseOut]) {
            self.brandStack.alpha = 1
            self.brandStack.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            window.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window.makeKeyAndVisible()
        }
    }
}
