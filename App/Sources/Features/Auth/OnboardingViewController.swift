import UIKit

@MainActor
final class OnboardingViewController: AppPageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .white

        let heading = AppStyle.label("선배 답변을\n더 정확하게 받는 방법", size: 28, weight: .bold)
        let attributed = NSMutableAttributedString(string: "선배 답변을\n더 정확하게 받는 방법")
        attributed.addAttribute(.foregroundColor, value: AppStyle.blue, range: NSRange(location: 0, length: 2))
        heading.attributedText = attributed
        contentStack.addArrangedSubview(heading)
        contentStack.addArrangedSubview(AppStyle.label("질문에 학년, 관심 전공, 상황을 같이 적으면 더 현실적인 답변을 받을 수 있어요.", size: 15, color: AppStyle.muted))

        contentStack.addArrangedSubview(makeTip(number: "1", label: "질문 전에,", text: "입학 / 전공 / 학교생활 중 카테고리를 골라요."))
        contentStack.addArrangedSubview(makeTip(number: "2", label: "“기숙사 어때” 보단,", text: "“1학년 기숙사 평일 루틴 알려줘”"))

        contentStack.addArrangedSubview(AppStyle.button("채팅 시작하기", primary: true) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            let tabs = AppTabBarController()
            tabs.selectedIndex = 1
            window.rootViewController = tabs
            window.makeKeyAndVisible()
        })
    }

    private func makeTip(number: String, label: String, text: String) -> UIView {
        let badge = AppStyle.label(number, size: 14, weight: .semibold, color: AppStyle.blue)
        badge.textAlignment = .center
        badge.backgroundColor = AppStyle.paleBlue
        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.widthAnchor.constraint(equalToConstant: 28).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let copy = UIStackView(arrangedSubviews: [
            AppStyle.label(label, size: 12, color: AppStyle.muted),
            AppStyle.label(text, size: 15, weight: .medium)
        ])
        copy.axis = .vertical
        copy.spacing = 2
        let row = UIStackView(arrangedSubviews: [badge, copy])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.backgroundColor = .white
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14)
        row.layer.cornerRadius = 16
        row.layer.borderWidth = 1
        row.layer.borderColor = AppStyle.line.cgColor
        return row
    }
}
