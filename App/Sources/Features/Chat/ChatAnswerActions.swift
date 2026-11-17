import UIKit

@MainActor
extension ChatConversationViewController {
    func addAnswerActions() {
        let like = actionChip("좋아요", width: 73) {}
        like.accessibilityIdentifier = "answer-like"
        like.addAction(UIAction { [weak like] _ in
            guard let like else { return }
            like.isSelected.toggle()
            Self.updateActionSelection(like)
        }, for: .touchUpInside)
        let more = actionChip("더 물어보기", width: 100) { [weak self] in
            self?.inputField.becomeFirstResponder()
        }
        more.accessibilityIdentifier = "answer-follow-up"
        let share = actionChip("공유", width: 60) { [weak self] in self?.shareAnswer() }
        let trailingSpace = UIView()
        trailingSpace.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [like, more, share, trailingSpace])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        messagesStack.addArrangedSubview(row)
    }

    static func updateActionSelection(_ button: UIButton) {
        let selected = button.isSelected
        var configuration = button.configuration ?? UIButton.Configuration.plain()
        configuration.baseForegroundColor = selected ? .white : ChatDetailPalette.ink
        configuration.background.backgroundColor = selected ? ChatDetailPalette.brand : .white
        configuration.background.strokeColor = selected ? .clear : ChatDetailPalette.border
        configuration.background.strokeWidth = selected ? 0 : 1
        button.configuration = configuration
        button.backgroundColor = selected ? ChatDetailPalette.brand : .white
        button.layer.borderWidth = selected ? 0 : 1
        button.accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    func actionChip(_ title: String, width: CGFloat, selected: Bool = false, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(selected ? .white : ChatDetailPalette.ink, for: .normal)
        button.backgroundColor = selected ? ChatDetailPalette.brand : .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = ChatDetailPalette.border.cgColor
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        configuration.baseForegroundColor = selected ? .white : ChatDetailPalette.ink
        configuration.background.backgroundColor = selected ? ChatDetailPalette.brand : .white
        configuration.background.strokeColor = selected ? .clear : ChatDetailPalette.border
        configuration.background.strokeWidth = selected ? 0 : 1
        configuration.background.cornerRadius = 20
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        button.configuration = configuration
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

}
