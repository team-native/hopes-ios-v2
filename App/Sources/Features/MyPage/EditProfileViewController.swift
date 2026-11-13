import UIKit

@MainActor
final class EditProfileViewController: AppPageViewController, UITextFieldDelegate, UITextViewDelegate {
    private let nameField = UITextField()
    private let introductionView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 14
        addHeader()
        addProfileForm()

        let saveButton = AppStyle.button("저장", primary: true) { [weak self] in self?.save() }
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(saveButton)

        DispatchQueue.main.async { [weak self] in
            self?.introductionView.becomeFirstResponder()
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
        introductionView.layer.borderColor = AppStyle.blue.withAlphaComponent(0.5).cgColor
        introductionView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 12, right: 12)
        introductionView.heightAnchor.constraint(equalToConstant: 94).isActive = true
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
        navigationController?.popViewController(animated: true)
    }
}
