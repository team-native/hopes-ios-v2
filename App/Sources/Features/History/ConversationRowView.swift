import UIKit

@MainActor
final class ConversationRowView: UIView, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)?
    var onDelete: (() -> Void)?
    var onBeginSwipe: (() -> Void)?
    var onSwipeEnded: ((Bool) -> Void)?

    private let revealWidth: CGFloat = 80
    private let contentButton = UIButton(type: .custom)
    private let deleteButton = UIButton(type: .system)
    private var startOffset: CGFloat = 0
    private var offset: CGFloat = 0
    private weak var metadataLabel: UILabel?
    private var contentInsetConstraints: [NSLayoutConstraint] = []
    private var contentTrailingConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(content: UIView, trashImage: UIImage?, metadataLabel: UILabel?) {
        self.metadataLabel = metadataLabel
        content.translatesAutoresizingMaskIntoConstraints = false
        contentButton.addPassthroughSubview(content)
        contentInsetConstraints = [
            content.topAnchor.constraint(equalTo: contentButton.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: contentButton.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentButton.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: contentButton.bottomAnchor, constant: -12)
        ]
        NSLayoutConstraint.activate(contentInsetConstraints)
        var configuration = UIButton.Configuration.plain()
        configuration.image = trashImage
        configuration.imagePlacement = .top
        configuration.imagePadding = 2
        configuration.title = "삭제"
        configuration.baseForegroundColor = .white
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12)
            return outgoing
        }
        deleteButton.configuration = configuration
        deleteButton.addAction(UIAction { [weak self] _ in self?.onDelete?() }, for: .touchUpInside)
        contentButton.addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
    }

    func setRevealed(_ revealed: Bool, animated: Bool) {
        offset = revealed ? -revealWidth : 0
        let changes = { self.applyOffset(self.offset) }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: changes)
        } else {
            changes()
        }
    }

    private func applyOffset(_ value: CGFloat) {
        contentTrailingConstraint?.constant = value
        layoutIfNeeded()
    }

    func setSwipeLayout(_ isSwiping: Bool) {
        let horizontal: CGFloat = isSwiping ? 16 : 0
        let vertical: CGFloat = isSwiping ? 14 : 12
        contentInsetConstraints[0].constant = vertical
        contentInsetConstraints[1].constant = horizontal
        contentInsetConstraints[2].constant = -horizontal
        contentInsetConstraints[3].constant = -vertical
    }

    func setMetadataVisible(_ visible: Bool) {
        metadataLabel?.isHidden = !visible
    }

    private func build() {
        backgroundColor = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
        clipsToBounds = true

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: topAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: revealWidth)
        ])

        contentButton.backgroundColor = .white
        contentButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentButton)
        NSLayoutConstraint.activate([
            contentButton.topAnchor.constraint(equalTo: topAnchor),
            contentButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])

        let trailing = contentButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        trailing.isActive = true
        contentTrailingConstraint = trailing

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        contentButton.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self).x
        switch gesture.state {
        case .began:
            startOffset = offset
            onBeginSwipe?()
        case .changed:
            offset = min(0, max(-revealWidth, startOffset + translation))
            applyOffset(offset)
        case .ended, .cancelled, .failed:
            let isRevealed = offset <= -revealWidth / 2
            setRevealed(isRevealed, animated: true)
            onSwipeEnded?(isRevealed)
        default:
            break
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }
}
