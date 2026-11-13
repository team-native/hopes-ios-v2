import UIKit

@MainActor
final class AIAnswerStyleViewController: AppPageViewController, UITextViewDelegate {
    private let defaults = UserDefaults.standard
    private let promptView = UITextView()
    private let promptPlaceholder = AppStyle.label("예: 답변은 항상 3문장 이내로 짧게 해줘.", size: 15,
        color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
    private let topSaveButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var promptHeightConstraint: NSLayoutConstraint!
    private var saveButtonBottomConstraint: NSLayoutConstraint?
    private let showsSavedPreview = ProcessInfo.processInfo.arguments.contains("--prompt-save-success")

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
        addPromptCard()
        configureSaveButton()
        pinSaveButtonToBottom()

        if showsSavedPreview {
            showSavedToast()
        }
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
        backButton.setImage(UIImage(named: "ai-answer-style-back-icon")?.withRenderingMode(.alwaysOriginal),
            for: .normal)
        backButton.accessibilityLabel = "뒤로"
        backButton.accessibilityIdentifier = "ai-answer-style-back"
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("개인 설정", size: 18, weight: .medium, color: UIColor(red: 20 / 255,
            green: 27 / 255, blue: 43 / 255, alpha: 1))
        let subtitle = AppStyle.label("AI 답변 스타일을 관리해요.", size: 12, color: UIColor(red: 107 / 255, green: 120 / 255,
            blue: 144 / 255, alpha: 1))
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical

        var configuration = UIButton.Configuration.plain()
        configuration.title = "저장"
        configuration.baseForegroundColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        topSaveButton.configuration = configuration
        topSaveButton.backgroundColor = .white
        topSaveButton.layer.cornerRadius = 10
        topSaveButton.layer.borderWidth = 1
        topSaveButton.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        topSaveButton.addTarget(self, action: #selector(savePrompt), for: .touchUpInside)
        topSaveButton.translatesAutoresizingMaskIntoConstraints = false
        topSaveButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        topSaveButton.accessibilityIdentifier = "ai-answer-style-save-top"

        let header = UIStackView(arrangedSubviews: [backButton, labels, topSaveButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addPromptCard() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let title = AppStyle.label("시스템 프롬프트", size: 15, weight: .medium, color: UIColor(red: 20 / 255,
            green: 27 / 255, blue: 43 / 255, alpha: 1))
        let subtitle = AppStyle.label("AI 응답을 만들 때 반영돼요.", size: 12, color: UIColor(red: 107 / 255,
            green: 120 / 255, blue: 144 / 255, alpha: 1))

        promptView.text = defaults.string(forKey: "answerStyle.systemPrompt")
            ?? ""
        promptView.font = .systemFont(ofSize: 15)
        promptView.textColor = AppStyle.ink
        promptView.backgroundColor = .white
        promptView.layer.cornerRadius = 16
        promptView.layer.borderWidth = 1
        promptView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        promptView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        promptView.delegate = self
        promptView.accessibilityIdentifier = "ai-answer-style-prompt"
        promptPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        promptView.addSubview(promptPlaceholder)
        NSLayoutConstraint.activate([
            promptPlaceholder.topAnchor.constraint(equalTo: promptView.topAnchor, constant: 14),
            promptPlaceholder.leadingAnchor.constraint(equalTo: promptView.leadingAnchor, constant: 20),
            promptPlaceholder.trailingAnchor.constraint(lessThanOrEqualTo: promptView.trailingAnchor, constant: -16)
        ])
        promptPlaceholder.isHidden = !promptView.text.isEmpty
        promptHeightConstraint = promptView.heightAnchor.constraint(equalToConstant: 220)
        promptHeightConstraint.isActive = true

        let heading = UIStackView(arrangedSubviews: [title, subtitle])
        heading.axis = .vertical
        heading.spacing = 2
        let content = UIStackView(arrangedSubviews: [heading, promptView])
        content.axis = .vertical
        content.spacing = 12
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
        var configuration = UIButton.Configuration.filled()
        configuration.title = "프롬프트 저장"
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
        saveButton.accessibilityIdentifier = "ai-answer-style-save-bottom"
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addAction(UIAction { [weak self] _ in self?.savePrompt() }, for: .touchUpInside)
    }

    @objc private func savePrompt() {
        let prompt = promptView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            showMessage("시스템 프롬프트를 입력해주세요")
            return
        }
        defaults.set(prompt, forKey: "answerStyle.systemPrompt")
        promptView.resignFirstResponder()
        promptView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
        promptHeightConstraint.constant = 220
        showSavedToast()
    }

    private func pinSaveButtonToBottom() {
        view.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        let bottomConstraint = saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -16)
        bottomConstraint.isActive = true
        saveButtonBottomConstraint = bottomConstraint
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1).cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1).cgColor
    }

    func textViewDidChange(_ textView: UITextView) {
        promptPlaceholder.isHidden = !textView.text.isEmpty
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
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
