import UIKit

@MainActor
final class EditProfileViewController: AppPageViewController, UITextViewDelegate {
    private let nameField = UITextField()
    private let introductionView = UITextView()
    private let showsSaveError = ProcessInfo.processInfo.arguments.contains("--profile-save-error")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 14
        addHeader()

        if showsSaveError {
            addErrorBanner()
            addAccountCard()
        }
        addProfileForm()

        let saveButton = AppStyle.button("저장", primary: true) { [weak self] in self?.save() }
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        if showsSaveError {
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(saveButton)
            NSLayoutConstraint.activate([
                saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ])
        } else {
            contentStack.addArrangedSubview(saveButton)
            DispatchQueue.main.async { [weak self] in
                self?.introductionView.becomeFirstResponder()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = AppStyle.ink
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("프로필 수정", size: 18, weight: .medium)
        let subtitle = AppStyle.label("마이페이지 > 프로필 수정", size: 12, color: AppStyle.muted)
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
        let heading = AppStyle.label("계정 정보 (수정 불가)", size: 14, color: AppStyle.muted)
        let emailRow = accountInfoRow(title: "이메일", value: UserProfileStore.shared.email)
        let departmentRow = accountInfoRow(title: "과 · 기수", value: "\(UserProfileStore.shared.department) · 10기")
        let stack = UIStackView(arrangedSubviews: [heading, emailRow, departmentRow])
        stack.axis = .vertical
        stack.spacing = 8
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
        let key = AppStyle.label(title, size: 14, color: AppStyle.muted)
        let text = AppStyle.label(value, size: 14)
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
        let nameLabel = AppStyle.label("이름", size: 14, color: AppStyle.muted)
        nameField.text = UserProfileStore.shared.name
        nameField.font = .systemFont(ofSize: 15)
        nameField.textColor = AppStyle.ink
        nameField.borderStyle = .none
        nameField.layer.cornerRadius = 16
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = AppStyle.line.cgColor
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        nameField.leftViewMode = .always
        nameField.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let introductionLabel = AppStyle.label("자기소개 (AI 응답 개인화에 활용돼요)", size: 14, color: AppStyle.muted)
        introductionView.text = UserProfileStore.shared.introduction
        introductionView.font = .systemFont(ofSize: 15)
        introductionView.textColor = AppStyle.ink
        introductionView.backgroundColor = .white
        introductionView.layer.cornerRadius = 16
        introductionView.layer.borderWidth = 1.5
        introductionView.layer.borderColor = showsSaveError ? AppStyle.line.cgColor : AppStyle.blue.withAlphaComponent(0.5).cgColor
        introductionView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 12, right: 12)
        introductionView.heightAnchor.constraint(equalToConstant: showsSaveError ? 110 : 96).isActive = true
        introductionView.delegate = self

        let fields = UIStackView(arrangedSubviews: [nameLabel, nameField, introductionLabel, introductionView])
        fields.axis = .vertical
        fields.spacing = 10
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
        textView.layer.borderColor = AppStyle.blue.withAlphaComponent(0.55).cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderColor = AppStyle.line.cgColor
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
