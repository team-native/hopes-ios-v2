import UIKit

@MainActor
final class MyPageViewController: AppPageViewController, UITextViewDelegate {
    private let nameField = UITextField()
    private let introductionView = UITextView()
    private let introductionPlaceholder = "예: 프론트엔드에 관심 많은 8기 학생이에요."
    private var didEditIntroduction = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        contentStack.spacing = 18
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        let brandHeader = addBrandHeader()
        contentStack.setCustomSpacing(19, after: brandHeader)
        let heading = AppStyle.label("마이페이지", size: 28, weight: .bold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(28, after: heading)

        let accountCard = makeAccountCard()
        let accountContainer = centered(accountCard, width: 354)
        contentStack.addArrangedSubview(accountContainer)
        contentStack.setCustomSpacing(28, after: accountContainer)

        let profileCard = makeProfileCard()
        contentStack.addArrangedSubview(centered(profileCard, width: 354))

        let save = AppStyle.button("저장", primary: true) { [weak self] in self?.saveProfile() }
        save.backgroundColor = UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1)
        save.layer.cornerRadius = 14
        save.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        save.widthAnchor.constraint(equalToConstant: 96).isActive = true
        save.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let saveRow = UIStackView(arrangedSubviews: [save, UIView()])
        saveRow.axis = .horizontal
        contentStack.addArrangedSubview(saveRow)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        hidesBottomBarWhenPushed = false
        tabBarController?.tabBar.isHidden = false
        nameField.text = UserProfileStore.shared.name
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addBrandHeader() -> UIView {
        let logo = UIView()
        logo.backgroundColor = .white
        logo.layer.cornerRadius = 12
        logo.layer.shadowColor = UIColor(red: 13 / 255, green: 26 / 255, blue: 46 / 255, alpha: 0.09).cgColor
        logo.layer.shadowOpacity = 1
        logo.layer.shadowRadius = 11
        logo.layer.shadowOffset = CGSize(width: 0, height: 8)
        logo.widthAnchor.constraint(equalToConstant: 42).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let letter = AppStyle.label("h", size: 26, weight: .bold, color: UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1))
        letter.textAlignment = .center
        logo.addSubview(letter)
        letter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            letter.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
            letter.centerYAnchor.constraint(equalTo: logo.centerYAnchor)
        ])

        let wordmark = AppStyle.label("hopes", size: 17, weight: .bold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let school = AppStyle.label("광주소프트웨어마이스터고", size: 11, weight: .medium, color: UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1))
        let brandLabels = UIStackView(arrangedSubviews: [wordmark, school])
        brandLabels.axis = .vertical
        brandLabels.spacing = 0
        let brand = UIStackView(arrangedSubviews: [logo, brandLabels])
        brand.axis = .horizontal
        brand.alignment = .center
        brand.spacing = 12

        let settings = UIButton(type: .system)
        settings.setTitle("설정", for: .normal)
        settings.setTitleColor(UIColor(red: 13 / 255, green: 138 / 255, blue: 229 / 255, alpha: 1), for: .normal)
        settings.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        settings.backgroundColor = .white
        settings.layer.cornerRadius = 14
        settings.layer.borderWidth = 1
        settings.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        settings.widthAnchor.constraint(equalToConstant: 54).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 36).isActive = true
        settings.addAction(UIAction { [weak self] _ in
            if let navigationController = self?.navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                self?.tabBarController?.selectedIndex = 3
            }
        }, for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [brand, UIView(), settings])
        header.axis = .horizontal
        header.alignment = .center
        contentStack.addArrangedSubview(header)
        return header
    }

    private func makeAccountCard() -> UIView {
        let card = makeCard(cornerRadius: 18)
        let title = AppStyle.label("계정 정보 (수정 불가)", size: 17, weight: .bold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let email = AppStyle.label("이메일: \(UserProfileStore.shared.email)", size: 13, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let department = AppStyle.label("전공: \(UserProfileStore.shared.department)", size: 13, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let content = UIStackView(arrangedSubviews: [title, email, department])
        content.axis = .vertical
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16)
        ])
        card.heightAnchor.constraint(equalToConstant: 128).isActive = true
        return card
    }

    private func makeProfileCard() -> UIView {
        let card = makeCard(cornerRadius: 18)
        let title = AppStyle.label("프로필", size: 18, weight: .bold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        let nameLabel = AppStyle.label("이름", size: 12, weight: .semibold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        nameField.text = UserProfileStore.shared.name
        nameField.font = .systemFont(ofSize: 15)
        nameField.textColor = UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1)
        nameField.borderStyle = .none
        nameField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let introLabel = AppStyle.label("자기소개 (AI 응답 개인화에 활용됩니다)", size: 13, weight: .semibold, color: UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1))
        introductionView.text = introductionPlaceholder
        introductionView.textColor = UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1)
        introductionView.font = .systemFont(ofSize: 15)
        introductionView.backgroundColor = .white
        introductionView.layer.cornerRadius = 14
        introductionView.layer.borderWidth = 1
        introductionView.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        introductionView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 12, right: 14)
        introductionView.heightAnchor.constraint(equalToConstant: 92).isActive = true
        introductionView.delegate = self

        let fields = UIStackView(arrangedSubviews: [title, nameLabel, nameField, introLabel, introductionView])
        fields.axis = .vertical
        fields.spacing = 10
        fields.setCustomSpacing(18, after: title)
        fields.setCustomSpacing(34, after: nameField)
        fields.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fields)
        NSLayoutConstraint.activate([
            fields.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            fields.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            fields.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])
        card.heightAnchor.constraint(equalToConstant: 326).isActive = true
        return card
    }

    private func makeCard(cornerRadius: CGFloat) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = cornerRadius
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 214 / 255, green: 224 / 255, blue: 237 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 13 / 255, green: 26 / 255, blue: 46 / 255, alpha: 0.09).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 11
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
        return card
    }

    private func centered(_ view: UIView, width: CGFloat) -> UIView {
        let container = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.widthAnchor.constraint(equalToConstant: width),
            view.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor)
        ])
        return container
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == introductionPlaceholder {
            textView.text = ""
            textView.textColor = UIColor(red: 14 / 255, green: 18 / 255, blue: 26 / 255, alpha: 1)
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        didEditIntroduction = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        textView.text = introductionPlaceholder
        textView.textColor = UIColor(red: 107 / 255, green: 122 / 255, blue: 148 / 255, alpha: 1)
    }

    private func saveProfile() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showMessage("이름을 입력해주세요")
            return
        }
        let introduction = didEditIntroduction
            ? (introductionView.text == introductionPlaceholder ? "" : introductionView.text)
            : UserProfileStore.shared.introduction
        UserProfileStore.shared.update(
            name: name,
            department: UserProfileStore.shared.department,
            email: UserProfileStore.shared.email,
            introduction: introduction
        )
        UserProfileStore.shared.markProfileSaved()
        view.endEditing(true)
        showProfileSavedToast()
    }

    private func showProfileSavedToast() {
        let message = AppStyle.label("프로필을 저장했어요", size: 13, weight: .medium, color: .white)
        let toast = UIStackView(arrangedSubviews: [message])
        toast.axis = .horizontal
        toast.alignment = .center
        toast.isLayoutMarginsRelativeArrangement = true
        toast.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        toast.backgroundColor = UIColor(red: 33 / 255, green: 41 / 255, blue: 56 / 255, alpha: 1)
        toast.layer.cornerRadius = 22
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak toast] in
            UIView.animate(withDuration: 0.2, animations: {
                toast?.alpha = 0
            }, completion: { _ in toast?.removeFromSuperview() })
        }
    }
}
