import UIKit

@MainActor
final class ConversationRowView: UIView, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)?
    var onDelete: (() -> Void)?
    var onBeginSwipe: (() -> Void)?

    private let revealWidth: CGFloat = 80
    private let contentButton = UIButton(type: .custom)
    private let deleteButton = UIButton(type: .system)
    private var startOffset: CGFloat = 0
    private var offset: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(content: UIView, trashImage: UIImage?) {
        content.translatesAutoresizingMaskIntoConstraints = false
        contentButton.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentButton.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: contentButton.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: contentButton.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: contentButton.bottomAnchor, constant: -14)
        ])
        var configuration = UIButton.Configuration.plain()
        configuration.image = trashImage
        configuration.imagePlacement = .top
        configuration.imagePadding = 2
        configuration.title = "삭제"
        configuration.baseForegroundColor = .white
        configuration.contentInsets = .zero
        deleteButton.configuration = configuration
        deleteButton.addAction(UIAction { [weak self] _ in self?.onDelete?() }, for: .touchUpInside)
        contentButton.addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
    }

    func setRevealed(_ revealed: Bool, animated: Bool) {
        offset = revealed ? -revealWidth : 0
        let changes = { self.contentButton.transform = CGAffineTransform(translationX: self.offset, y: 0) }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: changes)
        } else {
            changes()
        }
    }

    private func build() {
        backgroundColor = UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1)
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
            contentButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])

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
            contentButton.transform = CGAffineTransform(translationX: offset, y: 0)
        case .ended, .cancelled, .failed:
            setRevealed(offset <= -revealWidth / 2, animated: true)
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
