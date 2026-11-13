import UIKit

@MainActor
final class CommunityBoardPickerViewController: UIViewController {
    var onSelect: ((String) -> Void)?

    private let boards = ["전체", "8기", "9기", "10기", "11기"]
    private var selectedBoard: String
    private var boardButtons: [String: UIButton] = [:]

    init(selectedBoard: String) {
        self.selectedBoard = selectedBoard
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if let sheet = sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("community-board-picker")) { _ in 488 }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        let title = AppStyle.label("게시판 선택", size: 22, weight: .bold)
        let subtitle = AppStyle.label("다른 기수 게시판에도 글을 쓸 수 있어요.", size: 14, color: AppStyle.muted)
        let options = UIStackView()
        options.axis = .vertical

        boards.forEach { board in
            let button = makeBoardButton(board)
            boardButtons[board] = button
            options.addArrangedSubview(button)
            let divider = UIView()
            divider.backgroundColor = AppStyle.line
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            options.addArrangedSubview(divider)
        }
        updateSelection()

        let selectButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "선택"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        selectButton.configuration = configuration
        selectButton.layer.cornerRadius = 12
        selectButton.clipsToBounds = true
        selectButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        selectButton.addAction(UIAction { [weak self] _ in self?.confirmSelection() }, for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [title, subtitle, options, selectButton])
        content.axis = .vertical
        content.spacing = 12
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20)
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeBoardButton(_ board: String) -> UIButton {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .leading
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        let label = AppStyle.label(board, size: 15)
        let radio = UIImageView()
        radio.widthAnchor.constraint(equalToConstant: 22).isActive = true
        radio.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let row = UIStackView(arrangedSubviews: [label, UIView(), radio])
        row.axis = .horizontal
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.accessibilityIdentifier = board
        button.addAction(UIAction { [weak self] _ in
            self?.selectedBoard = board
            self?.updateSelection()
        }, for: .touchUpInside)
        return button
    }

    private func updateSelection() {
        boardButtons.forEach { board, button in
            let isSelected = board == selectedBoard
            button.subviews.compactMap { $0 as? UIStackView }
                .flatMap(\.arrangedSubviews)
                .compactMap { $0 as? UILabel }
                .first?.textColor = isSelected ? AppStyle.blue : AppStyle.ink
            if let radio = button.subviews.compactMap({ $0 as? UIStackView })
                .flatMap(\.arrangedSubviews)
                .compactMap({ $0 as? UIImageView }).first {
                radio.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                radio.tintColor = isSelected ? AppStyle.blue : AppStyle.line
            }
        }
    }

    private func confirmSelection() {
        let board = selectedBoard
        dismiss(animated: true) { [weak self] in self?.onSelect?(board) }
    }
}
