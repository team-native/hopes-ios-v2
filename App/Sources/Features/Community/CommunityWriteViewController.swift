import UIKit

@MainActor
final class CommunityWriteViewController: AppPageViewController, UITextViewDelegate {
    let titleField = UITextField()
    let bodyView = UITextView()
    let fieldBorderColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
    let bodyPlaceholder = "내용을 입력하세요"
    var selectedBoard = "10기"
    let boardValue = AppStyle.label("10기", size: 15, weight: .medium)
    let titleErrorLabel = AppStyle.label("", size: 12, color: .systemRed)
    let bodyErrorLabel = AppStyle.label("", size: 12, color: .systemRed)
    var titleErrorRow: UIStackView?
    var bodyErrorRow: UIStackView?
    var registrationErrorBanner: UIStackView?
    var shouldSimulateRegistrationFailure = true
    var previousNavigationBarHidden = false

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        contentStack.spacing = 12
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        scrollView.keyboardDismissMode = .interactive

        let header = makeHeader()
        let registerButton = makeRegisterButton()
        header.addArrangedSubview(registerButton)
        contentStack.addArrangedSubview(header)

        contentStack.addArrangedSubview(makeRegistrationErrorBanner())
        configureFormFields()
        contentStack.addArrangedSubview(makePrivacyNotice())
        view.accessibilityIdentifier = "community-write-screen"
    }

    private func configureFormFields() {
        contentStack.addArrangedSubview(makeBoardRow())
        configureTitleField()
        contentStack.addArrangedSubview(makeInputGroup(field: titleField, error: titleErrorLabel))
        configureBodyView()
        contentStack.addArrangedSubview(makeInputGroup(field: bodyView, error: bodyErrorLabel))
        contentStack.addArrangedSubview(UIView())
    }

    private func makeInputGroup(field: UIView, error: UILabel) -> UIStackView {
        let group = UIStackView(arrangedSubviews: [field, makeErrorRow(error)])
        group.axis = .vertical
        group.spacing = 6
        return group
    }

    private func makeRegisterButton() -> UIButton {
        let registerButton = UIButton(type: .system)
        var registerConfiguration = UIButton.Configuration.filled()
        registerConfiguration.title = "등록"
        registerConfiguration.baseBackgroundColor = AppStyle.blue
        registerConfiguration.baseForegroundColor = .white
        registerConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        registerButton.configuration = registerConfiguration
        registerButton.layer.cornerRadius = 10
        registerButton.clipsToBounds = true
        registerButton.accessibilityIdentifier = "community-register-post"
        registerButton.addAction(UIAction { [weak self] _ in self?.publish() }, for: .touchUpInside)
        registerButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return registerButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
        }
    }

    private func makeHeader() -> UIStackView {
        let close = UIButton(type: .system)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.setImage(UIImage(named: "community-write-close-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        close.accessibilityLabel = "닫기"
        close.accessibilityIdentifier = "community-write-close"
        close.addAction(UIAction { [weak self] _ in self?.cancel() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            close.widthAnchor.constraint(equalToConstant: 44),
            close.heightAnchor.constraint(equalToConstant: 44)
        ])

        let heading = AppStyle.label("글쓰기", size: 18, weight: .medium, color: AppStyle.ink)
        heading.heightAnchor.constraint(equalToConstant: 26).isActive = true
        let header = UIStackView(arrangedSubviews: [close, heading, UIView()])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        return header
    }

    private func makeBoardRow() -> UIButton {
        let label = AppStyle.label("게시판", size: 14, weight: .medium, color: AppStyle.muted)
        let chevronImage = UIImage(named: "community-write-chevron-icon")?.withRenderingMode(.alwaysOriginal)
        let chevron = UIImageView(image: chevronImage)
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 16).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let row = UIStackView(arrangedSubviews: [label, UIView(), boardValue, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        let button = UIButton(type: .custom)
        button.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 54)
        ])
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = fieldBorderColor.cgColor
        button.addAction(UIAction { [weak self] _ in self?.presentBoardPicker() }, for: .touchUpInside)
        return button
    }

    private func presentBoardPicker() {
        view.endEditing(true)
        let picker = CommunityBoardPickerViewController(selectedBoard: selectedBoard)
        picker.onSelect = { [weak self] board in
            self?.selectedBoard = board
            self?.boardValue.text = board
        }
        present(picker, animated: true)
    }

    private func configureTitleField() {
        titleField.placeholder = "제목"
        titleField.font = .systemFont(ofSize: 15)
        titleField.textColor = AppStyle.ink
        titleField.backgroundColor = .white
        titleField.layer.cornerRadius = 16
        titleField.layer.borderWidth = 1
        titleField.layer.borderColor = fieldBorderColor.cgColor
        titleField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        titleField.leftView = padding
        titleField.leftViewMode = .always
        titleField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
    }

    private func makeErrorRow(_ label: UILabel) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = .systemRed
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        row.isHidden = true
        if label === titleErrorLabel {
            titleErrorRow = row
        } else {
            bodyErrorRow = row
        }
        return row
    }

    private func configureBodyView() {
        bodyView.font = .systemFont(ofSize: 15)
        bodyView.textColor = AppStyle.muted
        bodyView.text = bodyPlaceholder
        bodyView.backgroundColor = .white
        bodyView.layer.cornerRadius = 16
        bodyView.layer.borderWidth = 1
        bodyView.layer.borderColor = fieldBorderColor.cgColor
        bodyView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        bodyView.heightAnchor.constraint(equalToConstant: 510).isActive = true
        bodyView.delegate = self
    }

    private func makePrivacyNotice() -> UIView {
        let lock = UIImageView(image: UIImage(named: "community-write-lock-icon")?.withRenderingMode(.alwaysOriginal))
        lock.widthAnchor.constraint(equalToConstant: 18).isActive = true
        lock.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("작성자는 기수만 표시돼요. 이름·학번은 다른 사용자에게 공개되지 않아요.", size: 12, color: AppStyle.muted)
        let notice = UIStackView(arrangedSubviews: [lock, message])
        notice.axis = .horizontal
        notice.alignment = .top
        notice.spacing = 8
        notice.isLayoutMarginsRelativeArrangement = true
        notice.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        notice.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        notice.layer.cornerRadius = 14
        return notice
    }

    private func makeRegistrationErrorBanner() -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = .systemRed
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("게시글을 등록하지 못했어요. 작성한 내용은 그대로 있어요. 다시 시도해 주세요.", size: 12, color: .systemRed)
        let banner = UIStackView(arrangedSubviews: [icon, message])
        banner.axis = .horizontal
        banner.alignment = .center
        banner.spacing = 8
        banner.isLayoutMarginsRelativeArrangement = true
        banner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        banner.backgroundColor = UIColor(red: 1, green: 0.945, blue: 0.949, alpha: 1)
        banner.layer.cornerRadius = 14
        banner.isHidden = true
        registrationErrorBanner = banner
        return banner
    }

}

@MainActor
extension CommunityWriteViewController {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == bodyPlaceholder {
            textView.text = ""
            textView.textColor = AppStyle.ink
        }
        if bodyErrorRow?.isHidden != false {
            bodyView.layer.borderColor = AppStyle.blue.withAlphaComponent(0.55).cgColor
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = bodyPlaceholder
            textView.textColor = AppStyle.muted
        }
        let borderColor = bodyErrorRow?.isHidden == false ? UIColor.systemRed.cgColor : fieldBorderColor.cgColor
        bodyView.layer.borderColor = borderColor
    }

    func textViewDidChange(_ textView: UITextView) {
        guard !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        setBodyError(false)
    }

    @objc private func titleDidChange() {
        guard !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        setTitleError(false)
    }

    @objc private func cancel() {
        let titleHasDraft = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyHasDraft = !bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            bodyView.text != bodyPlaceholder
        let hasDraft = titleHasDraft || bodyHasDraft
        guard hasDraft else {
            navigationController?.popViewController(animated: true)
            return
        }

        let alert = UIAlertController(
            title: "작성을 그만둘까요?",
            message: "지금 나가면 작성 중인 글이 사라져요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "계속 쓰기", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

}

@MainActor
extension CommunityWriteViewController {
}

@MainActor
extension CommunityWriteViewController {
    func publish() {
        view.endEditing(true)
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text == bodyPlaceholder
            ? ""
            : bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        setTitleError(titleText.isEmpty)
        setBodyError(bodyText.isEmpty)
        guard !titleText.isEmpty, !bodyText.isEmpty else {
            return
        }
        if shouldSimulateRegistrationFailure {
            // The prototype has no post API yet; keep the draft and reproduce one temporary registration failure.
            shouldSimulateRegistrationFailure = false
            registrationErrorBanner?.isHidden = false
            return
        }
        registrationErrorBanner?.isHidden = true
        CommunityPostStore.shared.add(title: titleText, body: bodyText, category: "질문", grade: selectedBoard)
        CommunityPostStore.shared.markPostPublished()
        navigationController?.popViewController(animated: true)
    }

    private func setTitleError(_ isError: Bool) {
        titleErrorLabel.text = isError ? "제목을 입력해 주세요." : nil
        titleErrorRow?.isHidden = !isError
        titleField.layer.borderWidth = isError ? 1.5 : 1
        titleField.layer.borderColor = isError ? UIColor.systemRed.cgColor : fieldBorderColor.cgColor
    }

    private func setBodyError(_ isError: Bool) {
        bodyErrorLabel.text = isError ? "내용을 입력해 주세요." : nil
        bodyErrorRow?.isHidden = !isError
        bodyView.layer.borderWidth = isError ? 1.5 : 1
        bodyView.layer.borderColor = isError ? UIColor.systemRed.cgColor : fieldBorderColor.cgColor
    }
}
