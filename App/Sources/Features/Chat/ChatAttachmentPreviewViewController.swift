import UIKit

@MainActor
final class ChatAttachmentPreviewViewController: UIViewController {
    let fileName: String
    let image: UIImage?
    var onSend: (() -> Void)?

    init(fileName: String, image: UIImage?) {
        self.fileName = fileName
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.canvas

        let topBar = makeTopBar()
        let previewCard = makePreviewCard()
        let send = makeSendButton()
        let stack = UIStackView(arrangedSubviews: [topBar, previewCard, send])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            previewCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 250)
        ])
    }

    private func makeTopBar() -> UIStackView {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = AppStyle.ink
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        close.widthAnchor.constraint(equalToConstant: 42).isActive = true
        close.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let title = AppStyle.label("첨부 미리보기", size: 18, weight: .bold)
        title.textAlignment = .center
        let topBar = UIStackView(arrangedSubviews: [close, title, UIView()])
        topBar.axis = .horizontal
        topBar.alignment = .center
        return topBar
    }

    private func makePreviewCard() -> UIView {
        let previewCard = AppStyle.card()
        previewCard.translatesAutoresizingMaskIntoConstraints = false
        let fileLabel = AppStyle.label(fileName, size: 14, weight: .medium, color: AppStyle.muted)
        fileLabel.textAlignment = .center
        fileLabel.translatesAutoresizingMaskIntoConstraints = false
        previewCard.addSubview(fileLabel)
        if let image {
            addImagePreview(to: previewCard, fileLabel: fileLabel, image: image)
        } else {
            addDocumentIcon(to: previewCard)
        }
        NSLayoutConstraint.activate([
            fileLabel.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            fileLabel.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),
            fileLabel.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -18)
        ])
        return previewCard
    }

    private func addImagePreview(to card: UIView, fileLabel: UILabel, image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            imageView.bottomAnchor.constraint(equalTo: fileLabel.topAnchor, constant: -12),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 520)
        ])
    }

    private func addDocumentIcon(to card: UIView) {
        let icon = UIImageView(image: UIImage(systemName: "doc.text.fill"))
        icon.tintColor = AppStyle.blue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 70),
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 76)
        ])
    }

    private func makeSendButton() -> UIButton {
        AppStyle.button("대화에 첨부", primary: true) { [weak self] in
            guard let self else { return }
            self.onSend?()
            self.dismiss(animated: true)
        }
    }
}
