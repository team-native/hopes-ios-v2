import UIKit

@MainActor
final class AIAnswerStyleViewController: AppPageViewController {
    private let defaults = UserDefaults.standard
    private let promptView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 14
        addHeader()
        addPromptCard()

        let saveButton = AppStyle.button("프롬프트 저장", primary: true) { [weak self] in
            guard let self else { return }
            let prompt = self.promptView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !prompt.isEmpty else {
                self.showMessage("시스템 프롬프트를 입력해주세요")
                return
            }
            self.defaults.set(prompt, forKey: "answerStyle.systemPrompt")
            self.navigationController?.popViewController(animated: true)
        }
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(saveButton)

        DispatchQueue.main.async { [weak self] in
            self?.promptView.becomeFirstResponder()
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
        let header = UIStackView(arrangedSubviews: [backButton, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addPromptCard() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24

        let title = AppStyle.label("시스템 프롬프트", size: 14, weight: .medium)
        let subtitle = AppStyle.label("AI 응답을 만들 때 반영돼요.", size: 12, color: AppStyle.muted)

        promptView.text = defaults.string(forKey: "answerStyle.systemPrompt")
            ?? "답변은 3문장 이내로 짧게, 예시를 하나씩 들어줘."
        promptView.font = .systemFont(ofSize: 15)
        promptView.textColor = AppStyle.ink
        promptView.backgroundColor = .white
        promptView.layer.cornerRadius = 16
        promptView.layer.borderWidth = 1.5
        promptView.layer.borderColor = AppStyle.blue.withAlphaComponent(0.5).cgColor
        promptView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 12, right: 12)
        promptView.heightAnchor.constraint(equalToConstant: 140).isActive = true

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
}
