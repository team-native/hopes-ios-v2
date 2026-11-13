import UIKit

@MainActor
final class EditProfileViewController: AppPageViewController, UITextViewDelegate {
    private let nameField = UITextField()
    private let introductionView = UITextView()
    private let introductionPlaceholder = AppStyle.label("예: 프론트엔드에 관심 많은 8기 학생이에요.", size: 15, color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
    private let showsSaveError = ProcessInfo.processInfo.arguments.contains("--profile-save-error")
    private var saveButtonBottomConstraint: NSLayoutConstraint?

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
        contentStack.spacing = 16
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
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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

        let title = AppStyle.label("프로필 수정", size: 18, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1))
        let subtitle = AppStyle.label("마이페이지 > 프로필 수정", size: 12, color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        let header = UIStackView(arrangedSubviews: [backButton, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addErrorBanner() {
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1)
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("저장하지 못했어요. 잠시 후 다시 시도해 주세요.", size: 12, color: icon.tintColor!)
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
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        let heading = AppStyle.label("계정 정보", size: 15, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1))
        let note = AppStyle.label("수정할 수 없는 정보예요.", size: 12, color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
        let headingStack = UIStackView(arrangedSubviews: [heading, note])
        headingStack.axis = .vertical
        headingStack.spacing = 2
        let emailRow = accountInfoRow(title: "이메일", value: UserProfileStore.shared.email)
        let departmentRow = accountInfoRow(title: "전공", value: UserProfileStore.shared.department)
        let stack = UIStackView(arrangedSubviews: [headingStack, emailRow, departmentRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func accountInfoRow(title: String, value: String) -> UIView {
        let key = AppStyle.label(title, size: 14, weight: .medium, color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1))
        let text = AppStyle.label(value, size: 14, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1))
        text.textAlignment = .right
        let spacer = UIView()
        let row = UIStackView(arrangedSubviews: [key, spacer, text])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }

    private func addProfileForm() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        let heading = AppStyle.label("프로필", size: 15, weight: .medium, color: UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1))
        let nameLabel = AppStyle.label("이름", size: 14, weight: .medium, color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1))
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

        let introductionLabel = AppStyle.label("자기소개 (AI 응답 개인화에 활용돼요)", size: 14, weight: .medium, color: UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1))
        introductionView.text = UserProfileStore.shared.introduction
        introductionView.font = .systemFont(ofSize: 15)
        introductionView.textColor = AppStyle.ink
        introductionView.backgroundColor = .white
        introductionView.layer.cornerRadius = 16
        introductionView.layer.borderWidth = 1
        introductionView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        introductionView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        introductionView.heightAnchor.constraint(equalToConstant: showsSaveError ? 110 : 96).isActive = true
        introductionView.delegate = self
        introductionView.accessibilityIdentifier = "profile-edit-introduction"
        introductionPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        introductionView.addSubview(introductionPlaceholder)
        NSLayoutConstraint.activate([
            introductionPlaceholder.topAnchor.constraint(equalTo: introductionView.topAnchor, constant: 14),
            introductionPlaceholder.leadingAnchor.constraint(equalTo: introductionView.leadingAnchor, constant: 20),
            introductionPlaceholder.trailingAnchor.constraint(lessThanOrEqualTo: introductionView.trailingAnchor, constant: -16)
        ])
        introductionPlaceholder.isHidden = !introductionView.text.isEmpty

        let nameFieldGroup = UIStackView(arrangedSubviews: [nameLabel, nameField])
        nameFieldGroup.axis = .vertical
        nameFieldGroup.spacing = 6
        let introductionGroup = UIStackView(arrangedSubviews: [introductionLabel, introductionView])
        introductionGroup.axis = .vertical
        introductionGroup.spacing = 6
        let fields = UIStackView(arrangedSubviews: [heading, nameFieldGroup, introductionGroup])
        fields.axis = .vertical
        fields.spacing = 12
        fields.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fields)
        NSLayoutConstraint.activate([
            fields.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            fields.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            fields.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            fields.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(card)
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

    private func addSaveButton() {
        let saveButton = UIButton(type: .system)
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
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -16)
        ])
        let bottomConstraint = saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        bottomConstraint.isActive = true
        saveButtonBottomConstraint = bottomConstraint
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let frame = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - view.safeAreaInsets.bottom - frame.minY)
        saveButtonBottomConstraint?.constant = -(16 + overlap)

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
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
