import UIKit

@MainActor
final class AIAnswerStyleViewController: AppPageViewController {
    private let defaults = UserDefaults.standard
    private let toneOptions = ["친근하게", "차분하게", "간결하게"]
    private let lengthOptions = ["짧게", "보통", "자세하게"]
    private var selectedTone: String
    private var selectedLength: String
    private let toneStack = UIStackView()
    private let lengthStack = UIStackView()

    init() {
        selectedTone = UserDefaults.standard.string(forKey: "answerStyle.tone") ?? "친근하게"
        selectedLength = UserDefaults.standard.string(forKey: "answerStyle.length") ?? "보통"
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI 답변 스타일"
        addHeading("나에게 맞는 답변", subtitle: "선배 답변을 읽기 편한 방식으로 설정해요")
        addSection("말투")
        configureOptions(toneStack, options: toneOptions, selected: selectedTone) { [weak self] value in
            self?.selectedTone = value
            self?.refreshOptions()
        }
        contentStack.addArrangedSubview(toneStack)

        addSection("답변 길이")
        configureOptions(lengthStack, options: lengthOptions, selected: selectedLength) { [weak self] value in
            self?.selectedLength = value
            self?.refreshOptions()
        }
        contentStack.addArrangedSubview(lengthStack)

        contentStack.addArrangedSubview(AppStyle.button("저장하기", primary: true) { [weak self] in
            guard let self else { return }
            self.defaults.set(self.selectedTone, forKey: "answerStyle.tone")
            self.defaults.set(self.selectedLength, forKey: "answerStyle.length")
            self.showMessage("답변 스타일을 저장했어요")
        })
    }

    private func configureOptions(_ stack: UIStackView, options: [String], selected: String, action: @escaping (String) -> Void) {
        stack.axis = .vertical
        stack.spacing = 8
        options.forEach { option in
            let button = AppStyle.button(option, action: { action(option) })
            button.accessibilityIdentifier = option
            button.contentHorizontalAlignment = .leading
            stack.addArrangedSubview(button)
        }
        updateSelection(in: stack, selected: selected)
    }

    private func refreshOptions() {
        updateSelection(in: toneStack, selected: selectedTone)
        updateSelection(in: lengthStack, selected: selectedLength)
    }

    private func updateSelection(in stack: UIStackView, selected: String) {
        stack.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
            let isSelected = button.accessibilityIdentifier == selected
            button.layer.borderColor = (isSelected ? AppStyle.blue : AppStyle.line).cgColor
            button.backgroundColor = isSelected ? AppStyle.paleBlue : .white
            button.setTitleColor(isSelected ? AppStyle.blue : AppStyle.ink, for: .normal)
        }
    }
}
