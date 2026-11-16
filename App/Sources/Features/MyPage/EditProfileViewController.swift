import UIKit

@MainActor
final class EditProfileViewController: AppPageViewController, UITextViewDelegate {
    let nameField = UITextField()
    let introductionView = UITextView()
    let introductionPlaceholder = AppStyle.label("예: 프론트엔드에 관심 많은 8기 학생이에요.", size: 15,
        color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
    let showsSaveError = ProcessInfo.processInfo.arguments.contains("--profile-save-error")
    var accountCard: UIView?
    var profileSectionHeading: UILabel?
    var saveButton: UIButton?
    var saveButtonBottomConstraint: NSLayoutConstraint?
    var saveButtonLeadingConstraint: NSLayoutConstraint?
    var saveButtonTrailingConstraint: NSLayoutConstraint?
    var saveButtonHeightConstraint: NSLayoutConstraint?
    var scrollBottomConstraint: NSLayoutConstraint?
    var keyboardScrollBottomConstraint: NSLayoutConstraint?
    var contentTopConstraint: NSLayoutConstraint?
    var isKeyboardLayoutActive = false
    var isCompactKeyboardLayoutActive = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        contentStack.spacing = showsSaveError ? 14 : 16
        addHeader()

        if showsSaveError {
            addErrorBanner()
        }
        addAccountCard()
        addProfileForm()
        addSaveButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    private func addHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "profile-edit-back-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backButton.accessibilityLabel = "뒤로"
        backButton.accessibilityIdentifier = "profile-edit-back"
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("프로필 수정", size: 18, weight: .medium, color: UIColor(red: 20 / 255,
            green: 27 / 255, blue: 43 / 255, alpha: 1))
        let subtitle = AppStyle.label("마이페이지 > 프로필 수정", size: 12, color: UIColor(red: 107 / 255, green: 120 / 255,
            blue: 144 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        let header = UIStackView(arrangedSubviews: [backButton, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12

        let pinnedTop = UIView()
        pinnedTop.translatesAutoresizingMaskIntoConstraints = false
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTop)
        pinnedTop.addSubview(header)
        NSLayoutConstraint.activate([
            pinnedTop.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pinnedTop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pinnedTop.heightAnchor.constraint(equalToConstant: 56),
            header.topAnchor.constraint(equalTo: pinnedTop.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: pinnedTop.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: pinnedTop.trailingAnchor, constant: -20),
            header.heightAnchor.constraint(equalToConstant: 44)
        ])

        view.constraints.first(where: {
            $0.firstItem === scrollView && $0.firstAttribute == .top
        })?.isActive = false
        scrollView.topAnchor.constraint(equalTo: pinnedTop.bottomAnchor).isActive = true
        contentTopConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        })
        contentTopConstraint?.constant = showsSaveError ? 10 : 12
    }

    private func addErrorBanner() {
        let icon = UIImageView(image: UIImage(named: "ProfileSaveError")?.withRenderingMode(.alwaysOriginal))
        let errorColor = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("저장하지 못했어요. 잠시 후 다시 시도해 주세요.", size: 12, color: errorColor)
        let banner = UIStackView(arrangedSubviews: [icon, message])
        banner.axis = .horizontal
        banner.alignment = .center
        banner.spacing = 8
        banner.isLayoutMarginsRelativeArrangement = true
        banner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        banner.backgroundColor = UIColor(red: 1, green: 0.945, blue: 0.949, alpha: 1)
        banner.layer.cornerRadius = 14
        contentStack.addArrangedSubview(banner)
    }

    private func addAccountCard() {
        let card = AppStyle.card()
        accountCard = card
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        let heading = AppStyle.label(
            showsSaveError ? "계정 정보 (수정 불가)" : "계정 정보",
            size: showsSaveError ? 14 : 15,
            weight: .medium,
            color: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
        )
        heading.heightAnchor.constraint(equalToConstant: showsSaveError ? 20 : 24).isActive = true
        var headerItems: [UIView] = [heading]
        if !showsSaveError {
            let caption = AppStyle.label("수정할 수 없는 정보예요.", size: 12, color: AppStyle.muted)
            caption.heightAnchor.constraint(equalToConstant: 16).isActive = true
            headerItems.append(caption)
        }
        let header = UIStackView(arrangedSubviews: headerItems)
        header.axis = .vertical
        header.spacing = 0
        if !showsSaveError {
            header.setCustomSpacing(2, after: heading)
        }
        let rows: [UIView] = [
            accountInfoRow(title: "이메일", value: UserProfileStore.shared.email),
            accountInfoRow(
                title: showsSaveError ? "과 · 기수" : "전공",
                value: showsSaveError
                    ? "\(UserProfileStore.shared.department) · \(UserProfileStore.shared.generation)"
                    : UserProfileStore.shared.department
            )
        ]
        let stack = UIStackView(arrangedSubviews: [header] + rows)
        stack.axis = .vertical
        stack.spacing = showsSaveError ? 8 : 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 17),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -17)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func accountInfoRow(title: String, value: String) -> UIView {
        let key = AppStyle.label(title, size: 14, weight: .medium, color: UIColor(red: 107 / 255, green: 120 / 255,
            blue: 144 / 255, alpha: 1))
        let text = AppStyle.label(value, size: 14, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255,
            blue: 43 / 255, alpha: 1))
        text.textAlignment = .right
        let spacer = UIView()
        let row = UIStackView(arrangedSubviews: [key, spacer, text])
        row.axis = .horizontal
        row.alignment = .center
        key.heightAnchor.constraint(equalToConstant: 20).isActive = true
        text.heightAnchor.constraint(equalToConstant: 20).isActive = true
        row.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return row
    }

}

@MainActor
extension EditProfileViewController {
    func addProfileForm() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        let heading = AppStyle.label("프로필", size: 15, weight: .medium, color: UIColor(red: 20 / 255,
            green: 27 / 255, blue: 43 / 255, alpha: 1))
        heading.heightAnchor.constraint(equalToConstant: 24).isActive = true
        profileSectionHeading = heading
        let nameLabel = AppStyle.label("이름", size: 14, weight: .medium, color: UIColor(red: 107 / 255,
            green: 120 / 255, blue: 144 / 255, alpha: 1))
        nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        configureNameField()
        let introductionLabel = configureIntroductionField()
        let nameFieldGroup = makeLabeledField(label: nameLabel, field: nameField)
        let introductionFieldGroup = makeLabeledField(label: introductionLabel, field: introductionView)
        let profileFields: [UIView] = showsSaveError
            ? [nameFieldGroup, introductionFieldGroup]
            : [heading, nameFieldGroup, introductionFieldGroup]
        let fields = UIStackView(arrangedSubviews: profileFields)
        fields.axis = .vertical
        fields.spacing = 12
        fields.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fields)
        NSLayoutConstraint.activate([
            fields.topAnchor.constraint(equalTo: card.topAnchor, constant: 17),
            fields.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            fields.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            fields.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -17)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func configureNameField() {
        nameField.text = UserProfileStore.shared.name
        nameField.font = .systemFont(ofSize: 15)
        nameField.textColor = AppStyle.ink
        nameField.borderStyle = .none
        nameField.layer.cornerRadius = 16
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        nameField.leftViewMode = .always
        nameField.accessibilityIdentifier = "profile-edit-name"
        nameField.heightAnchor.constraint(equalToConstant: 54).isActive = true

    }

    private func configureIntroductionField() -> UILabel {
        let label = AppStyle.label("자기소개 (AI 응답 개인화에 활용돼요)", size: 14, weight: .medium,
            color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1))
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        introductionView.text = UserProfileStore.shared.introduction
        introductionView.font = .systemFont(ofSize: 15)
        introductionView.textColor = AppStyle.ink
        introductionView.backgroundColor = .white
        introductionView.layer.cornerRadius = 16
        introductionView.layer.borderWidth = 1
        introductionView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255,
            alpha: 1).cgColor
        introductionView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        introductionView.heightAnchor.constraint(equalToConstant: showsSaveError ? 110 : 96).isActive = true
        introductionView.delegate = self
        introductionView.accessibilityIdentifier = "profile-edit-introduction"
        introductionPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        introductionView.addSubview(introductionPlaceholder)
        NSLayoutConstraint.activate([
            introductionPlaceholder.topAnchor.constraint(equalTo: introductionView.topAnchor, constant: 14),
            introductionPlaceholder.leadingAnchor.constraint(equalTo: introductionView.leadingAnchor, constant: 20),
            introductionPlaceholder.trailingAnchor.constraint(lessThanOrEqualTo: introductionView.trailingAnchor,
                constant: -16)
        ])
        introductionPlaceholder.isHidden = !introductionView.text.isEmpty

        return label
    }

    private func makeLabeledField(label: UIView, field: UIView) -> UIStackView {
        let group = UIStackView(arrangedSubviews: [label, field])
        group.axis = .vertical
        group.spacing = 6
        return group
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1).cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
    }

    func textViewDidChange(_ textView: UITextView) {
        introductionPlaceholder.isHidden = !textView.text.isEmpty
    }
}

@MainActor
extension EditProfileViewController {
    private func addSaveButton() {
        let saveButton = UIButton(type: .system)
        self.saveButton = saveButton
        var configuration = UIButton.Configuration.filled()
        configuration.title = "저장"
        configuration.baseBackgroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        saveButton.configuration = configuration
        saveButton.layer.cornerRadius = 12
        saveButton.clipsToBounds = true
        saveButton.accessibilityIdentifier = "profile-edit-save"
        saveButton.addAction(UIAction { [weak self] _ in self?.save() }, for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)

        if let bottomConstraint = view.constraints.first(where: {
            $0.firstItem === scrollView && $0.firstAttribute == .bottom
        }) {
            bottomConstraint.isActive = false
        }
        let leadingConstraint = saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        let trailingConstraint = saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        let heightConstraint = saveButton.heightAnchor.constraint(equalToConstant: 50)
        let scrollBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -16)
        saveButtonLeadingConstraint = leadingConstraint
        saveButtonTrailingConstraint = trailingConstraint
        saveButtonHeightConstraint = heightConstraint
        self.scrollBottomConstraint = scrollBottomConstraint
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            heightConstraint,
            scrollBottomConstraint
        ])
        let bottomConstraint = saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -16)
        bottomConstraint.isActive = true
        saveButtonBottomConstraint = bottomConstraint
    }

    private func save() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showMessage("이름을 입력해주세요")
            return
        }
        UserProfileStore.shared.update(
            name: name,
            department: UserProfileStore.shared.department,
            email: UserProfileStore.shared.email,
            introduction: introductionView.text
        )
        UserProfileStore.shared.markProfileSaved()
        navigationController?.popViewController(animated: true)
    }
}
