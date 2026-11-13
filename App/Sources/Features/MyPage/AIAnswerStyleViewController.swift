import UIKit

@MainActor
final class AIAnswerStyleViewController: AppPageViewController {
    private let defaults = UserDefaults.standard
    private let promptView = UITextView()
    private let topSaveButton = UIButton(type: .system)
    private let saveButton = AppStyle.button("프롬프트 저장", primary: true) {}
    private var promptHeightConstraint: NSLayoutConstraint!
    private var didSave = false
    private let showsSavedPreview = ProcessInfo.processInfo.arguments.contains("--prompt-save-success")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 14
        addHeader()
        addPromptCard()
        configureSaveButton()

        if showsSavedPreview {
            didSave = true
            promptHeightConstraint.constant = 220
            topSaveButton.isHidden = false
            pinSaveButtonToBottom()
            showSavedToast()
        } else {
            contentStack.addArrangedSubview(saveButton)
            DispatchQueue.main.async { [weak self] in
                self?.promptView.becomeFirstResponder()
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

        let title = AppStyle.label("개인 설정", size: 18, weight: .medium)
        let subtitle = AppStyle.label("AI 답변 스타일을 관리해요.", size: 12, color: AppStyle.muted)
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical

        topSaveButton.setTitle("저장", for: .normal)
        topSaveButton.setTitleColor(AppStyle.blue, for: .normal)
        topSaveButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        topSaveButton.backgroundColor = .white
        topSaveButton.layer.cornerRadius = 10
        topSaveButton.layer.borderWidth = 1
        topSaveButton.layer.borderColor = AppStyle.line.cgColor
        topSaveButton.isHidden = true
        topSaveButton.addTarget(self, action: #selector(savePrompt), for: .touchUpInside)
        topSaveButton.translatesAutoresizingMaskIntoConstraints = false
        topSaveButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        topSaveButton.heightAnchor.constraint(equalToConstant: 38).isActive = true

        let header = UIStackView(arrangedSubviews: [backButton, labels, topSaveButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addPromptCard() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24

        let title = AppStyle.label("시스템 프롬프트", size: 15, weight: .medium)
        let subtitle = AppStyle.label("AI 응답을 만들 때 반영돼요.", size: 12, color: AppStyle.muted)

        promptView.text = defaults.string(forKey: "answerStyle.systemPrompt")
            ?? "답변은 3문장 이내로 짧게, 예시를 하나씩 들어줘."
        promptView.font = .systemFont(ofSize: 15)
        promptView.textColor = AppStyle.ink
        promptView.backgroundColor = .white
        promptView.layer.cornerRadius = 16
        promptView.layer.borderWidth = 1
        promptView.layer.borderColor = AppStyle.line.cgColor
        promptView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 12, right: 12)
        promptHeightConstraint = promptView.heightAnchor.constraint(equalToConstant: 140)
        promptHeightConstraint.isActive = true

        let content = UIStackView(arrangedSubviews: [title, subtitle, promptView])
        content.axis = .vertical
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func configureSaveButton() {
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.addAction(UIAction { [weak self] _ in self?.savePrompt() }, for: .touchUpInside)
    }

    @objc private func savePrompt() {
        let prompt = promptView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            showMessage("시스템 프롬프트를 입력해주세요")
            return
        }
        defaults.set(prompt, forKey: "answerStyle.systemPrompt")
        didSave = true
        promptView.resignFirstResponder()
        promptView.layer.borderColor = AppStyle.line.cgColor
        promptHeightConstraint.constant = 220
        topSaveButton.isHidden = false

        if saveButton.superview === contentStack {
            contentStack.removeArrangedSubview(saveButton)
            saveButton.removeFromSuperview()
            pinSaveButtonToBottom()
        }
        showSavedToast()
    }

    private func pinSaveButtonToBottom() {
        guard saveButton.superview !== view else { return }
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func showSavedToast() {
        let check = UIView()
        check.backgroundColor = AppStyle.blue
        check.layer.cornerRadius = 11
        check.widthAnchor.constraint(equalToConstant: 22).isActive = true
        check.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        check.addSubview(checkmark)
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: check.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: check.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 12),
            checkmark.heightAnchor.constraint(equalToConstant: 12)
        ])

        let message = AppStyle.label("다음 답변부터 반영돼요", size: 13, weight: .medium, color: .white)
        let toast = UIStackView(arrangedSubviews: [check, message])
        toast.axis = .horizontal
        toast.alignment = .center
        toast.spacing = 10
        toast.isLayoutMarginsRelativeArrangement = true
        toast.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        toast.backgroundColor = UIColor(red: 0.13, green: 0.16, blue: 0.22, alpha: 1)
        toast.layer.cornerRadius = 26
        toast.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        toast.layer.shadowOpacity = 1
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 5)
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -32)
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak toast] in
            UIView.animate(withDuration: 0.2, animations: {
                toast?.alpha = 0
            }, completion: { _ in
                toast?.removeFromSuperview()
            })
        }
    }
}
