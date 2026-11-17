import UIKit

@MainActor
final class CommunityBoardPickerViewController: UIViewController {
    var onSelect: ((String) -> Void)?

    private let boards = ["전체", "8기", "9기", "10기", "11기"]
    private var selectedBoard: String
    private var boardButtons: [String: UIButton] = [:]
    private let dimView = UIView()
    private let sheetView = UIView()
    private let sheetHeight: CGFloat = 482

    init(selectedBoard: String) {
        self.selectedBoard = selectedBoard
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        configureDimView()
        configureSheet()
        updateSelection()
    }

    private func configureDimView() {
        dimView.backgroundColor = UIColor(red: 20 / 255, green: 28 / 255, blue: 43 / 255, alpha: 0.32)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPicker)))
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureSheet() {
        sheetView.backgroundColor = .white
        sheetView.layer.cornerRadius = 28
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.accessibilityIdentifier = "community-board-picker"
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        let title = AppStyle.label("게시판 선택", size: 22, weight: .bold)
        title.heightAnchor.constraint(equalToConstant: 30).isActive = true
        let subtitle = AppStyle.label("다른 기수 게시판에도 글을 쓸 수 있어요.", size: 14, color: AppStyle.muted)
        subtitle.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let options = UIStackView()
        options.axis = .vertical
        for (index, board) in boards.enumerated() {
            let button = makeBoardButton(board)
            boardButtons[board] = button
            options.addArrangedSubview(button)
            guard index < boards.count - 1 else { continue }
            let divider = UIView()
            divider.backgroundColor = AppStyle.line
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            options.addArrangedSubview(divider)
        }
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 21).isActive = true
        let content = UIStackView(arrangedSubviews: [
            AppStyle.sheetHandle(), title, subtitle, options, makeSelectButton(), spacer
        ])
        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.insetsLayoutMarginsFromSafeArea = false
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20)
        content.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(content)
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            sheetView.heightAnchor.constraint(equalToConstant: sheetHeight),
            content.topAnchor.constraint(equalTo: sheetView.topAnchor),
            content.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor)
        ])
    }

    private func makeSelectButton() -> UIButton {
        let selectButton = UIButton(type: .custom)
        selectButton.setTitle("선택", for: .normal)
        selectButton.setTitleColor(.white, for: .normal)
        selectButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        selectButton.backgroundColor = AppStyle.blue
        selectButton.layer.cornerRadius = 12
        selectButton.accessibilityIdentifier = "community-board-picker-select"
        selectButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        selectButton.addAction(UIAction { [weak self] _ in self?.confirmSelection() }, for: .touchUpInside)
        return selectButton
    }

    private func makeBoardButton(_ board: String) -> UIButton {
        let label = AppStyle.label(board, size: 15)
        let radio = UIView()
        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = 1
        let check = UIImageView(image: UIImage(named: "DepartmentPickerCheck")?.withRenderingMode(.alwaysOriginal))
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        radio.addSubview(check)
        let row = UIStackView(arrangedSubviews: [label, UIView(), radio])
        row.axis = .horizontal
        row.alignment = .center
        row.isUserInteractionEnabled = false
        let button = UIButton(type: .custom)
        button.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radio.widthAnchor.constraint(equalToConstant: 22),
            radio.heightAnchor.constraint(equalToConstant: 22),
            check.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: radio.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 14),
            check.heightAnchor.constraint(equalToConstant: 14),
            button.heightAnchor.constraint(equalToConstant: 52),
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.accessibilityIdentifier = board
        button.accessibilityLabel = board
        button.addAction(UIAction { [weak self] _ in
            self?.selectedBoard = board
            self?.updateSelection()
        }, for: .touchUpInside)
        return button
    }

    private func updateSelection() {
        boardButtons.forEach { board, button in
            let isSelected = board == selectedBoard
            guard let row = button.subviews.first as? UIStackView,
                  let label = row.arrangedSubviews.first as? UILabel,
                  let radio = row.arrangedSubviews.last,
                  let check = radio.subviews.first else { return }
            label.font = .systemFont(ofSize: 15, weight: isSelected ? .medium : .regular)
            label.textColor = isSelected ? AppStyle.blue : AppStyle.ink
            radio.backgroundColor = isSelected ? AppStyle.blue : .white
            radio.layer.borderColor = (isSelected ? AppStyle.blue : AppStyle.line).cgColor
            check.isHidden = !isSelected
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }

    @objc private func dismissPicker() {
        dismiss(animated: true)
    }

    private func confirmSelection() {
        let board = selectedBoard
        let handler = onSelect
        dismiss(animated: true) { handler?(board) }
    }
}
