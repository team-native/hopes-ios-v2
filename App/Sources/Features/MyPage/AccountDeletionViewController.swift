import UIKit

@MainActor
final class AccountDeletionViewController: UIViewController, UITextFieldDelegate {
    static let wrongPasswordMessage = "비밀번호가 맞지 않아요. 다시 확인해 주세요."
    static let emptyPasswordMessage = "비밀번호를 입력해 주세요."

    let passwordField = UITextField()
    let deleteButton = UIButton(type: .custom)
    let errorLabel = AppStyle.label("", size: 12, color: AccountDeletionPalette.danger)
    private(set) var errorRow = UIStackView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let passwordCard = UIView()
    private var buttonBottomConstraint: NSLayoutConstraint?
    private var buttonBelowCardConstraint: NSLayoutConstraint?
    private var scrollBottomToButton: NSLayoutConstraint?
    private var scrollBottomToKeyboard: NSLayoutConstraint?
    private(set) var isDeleting = false
    var accountDeleter: (String) async throws -> Void = { password in
        try await AccountAPI.deleteAccount(password: password)
    }
    var hasSession: () -> Bool = { AccessTokenStore.shared.hasToken }
    var onDeleted: () -> Void = { AuthSessionRouter.finishAccountDeletion() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.canvas
        view.accessibilityIdentifier = "account-deletion-screen"
        let topBar = makeTopBar()
        configureScroll(below: topBar)
        contentStack.addArrangedSubview(makeNoticeCard())
        contentStack.addArrangedSubview(makePasswordCard())
        configureDeleteButton()
        if ProcessInfo.processInfo.arguments.contains("--account-deletion-error") {
            passwordField.text = "password1"
            showError(Self.wrongPasswordMessage)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }

    func confirmDeletion() {
        guard !isDeleting else { return }
        let password = passwordField.text ?? ""
        guard !password.isEmpty else {
            showError(Self.emptyPasswordMessage)
            return
        }
        view.endEditing(true)
        let alert = UIAlertController(
            title: "정말 탈퇴할까요?",
            message: "계정과 대화 기록이 모두 삭제되고 되돌릴 수 없어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴하기", style: .destructive) { [weak self] _ in
            self?.deleteAccount(password: password)
        })
        present(alert, animated: true)
    }

    func deleteAccount(password: String) {
        guard hasSession() else {
            showMessage("로그인한 계정만 탈퇴할 수 있어요.")
            return
        }
        setDeleting(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.accountDeleter(password)
                self.setDeleting(false)
                self.onDeleted()
            } catch {
                self.setDeleting(false)
                self.handleDeletionFailure(error)
            }
        }
    }

    func handleDeletionFailure(_ error: Error) {
        switch error as? APIError {
        case .unauthorized?:
            showError(Self.wrongPasswordMessage)
        case let apiError?:
            showMessage(apiError.message)
        case nil:
            showMessage("탈퇴하지 못했어요. 잠시 후 다시 시도해 주세요.")
        }
    }

    func showError(_ message: String) {
        errorLabel.text = message
        errorRow.isHidden = false
        passwordField.layer.borderColor = AccountDeletionPalette.danger.cgColor
        passwordField.layer.borderWidth = 1.5
    }

    private func clearError() {
        errorRow.isHidden = true
        let focused = passwordField.isFirstResponder
        passwordField.layer.borderColor = (focused ? AccountDeletionPalette.focus : AppStyle.line).cgColor
        passwordField.layer.borderWidth = focused ? 1.5 : 1
    }

    private func setDeleting(_ deleting: Bool) {
        isDeleting = deleting
        deleteButton.isEnabled = !deleting
        deleteButton.alpha = deleting ? 0.6 : 1
        deleteButton.setTitle(deleting ? "탈퇴하는 중…" : "탈퇴하기", for: .normal)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard errorRow.isHidden else { return }
        textField.layer.borderColor = AccountDeletionPalette.focus.cgColor
        textField.layer.borderWidth = 1.5
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard errorRow.isHidden else { return }
        clearError()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmDeletion()
        return true
    }

    @objc private func passwordDidChange() {
        if !errorRow.isHidden { clearError() }
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let overlap = max(0, view.bounds.maxY - view.convert(frame, from: nil).minY)
        let isVisible = overlap > 0
        scrollBottomToKeyboard?.constant = -overlap
        scrollBottomToButton?.isActive = !isVisible
        scrollBottomToKeyboard?.isActive = isVisible
        buttonBottomConstraint?.isActive = !isVisible
        buttonBelowCardConstraint?.isActive = isVisible
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

enum AccountDeletionPalette {
    static let danger = UIColor(red: 239 / 255, green: 68 / 255, blue: 88 / 255, alpha: 1)
    static let focus = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
    static let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
}

@MainActor
private extension AccountDeletionViewController {
    func makeTopBar() -> UIView {
        let back = UIButton(type: .custom)
        back.setImage(UIImage(named: "SettingsBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
        back.accessibilityLabel = "뒤로"
        back.accessibilityIdentifier = "account-deletion-back"
        back.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        let title = AppStyle.label("회원탈퇴", size: 18, weight: .medium)
        title.heightAnchor.constraint(equalToConstant: 26).isActive = true
        let caption = AppStyle.label("계정과 데이터를 영구 삭제해요.", size: 12, color: AppStyle.muted)
        caption.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let labels = UIStackView(arrangedSubviews: [title, caption])
        labels.axis = .vertical
        let bar = UIStackView(arrangedSubviews: [back, labels])
        bar.axis = .horizontal
        bar.alignment = .center
        bar.spacing = 12
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            back.widthAnchor.constraint(equalToConstant: 44),
            back.heightAnchor.constraint(equalToConstant: 44),
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bar.heightAnchor.constraint(equalToConstant: 44)
        ])
        return bar
    }

    func configureScroll(below topBar: UIView) {
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        return card
    }

    func pin(_ content: UIView, in card: UIView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    func noticeLine(_ text: String, color: UIColor = AppStyle.ink) -> UILabel {
        let label = AppStyle.label(text, size: 14, weight: .medium, color: color)
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        return label
    }

    func makeNoticeCard() -> UIView {
        let lines = UIStackView(arrangedSubviews: [
            noticeLine("탈퇴하면 이 정보가 삭제돼요"),
            noticeLine("· 프로필과 계정 정보"),
            noticeLine("· 지난 대화와 메시지"),
            noticeLine("· 보낸 문의 내역"),
            noticeLine("삭제한 정보는 다시 되돌릴 수 없어요.", color: AccountDeletionPalette.danger)
        ])
        lines.axis = .vertical
        lines.spacing = 8
        let card = makeCard()
        card.accessibilityIdentifier = "account-deletion-notice"
        pin(lines, in: card)
        return card
    }

    func makePasswordCard() -> UIView {
        let label = AppStyle.label("비밀번호 확인", size: 14, weight: .medium, color: AppStyle.muted)
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password
        passwordField.font = .systemFont(ofSize: 15)
        passwordField.textColor = AppStyle.ink
        passwordField.attributedPlaceholder = NSAttributedString(string: "현재 비밀번호를 입력해 주세요", attributes: [
            .font: UIFont.systemFont(ofSize: 15), .foregroundColor: AccountDeletionPalette.tertiary
        ])
        passwordField.returnKeyType = .done
        passwordField.delegate = self
        passwordField.layer.cornerRadius = 16
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = AppStyle.line.cgColor
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        passwordField.leftViewMode = .always
        passwordField.accessibilityIdentifier = "account-deletion-password"
        passwordField.heightAnchor.constraint(equalToConstant: 54).isActive = true
        passwordField.addTarget(self, action: #selector(passwordDidChange), for: .editingChanged)

        let icon = UIImageView(image: UIImage(named: "inquiry-error-alert"))
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
        errorLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        errorRow = UIStackView(arrangedSubviews: [icon, errorLabel])
        errorRow.axis = .horizontal
        errorRow.alignment = .center
        errorRow.spacing = 4
        errorRow.isHidden = true
        errorRow.accessibilityIdentifier = "account-deletion-error"

        let group = UIStackView(arrangedSubviews: [label, passwordField, errorRow])
        group.axis = .vertical
        group.spacing = 6
        let card = passwordCard
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        pin(group, in: card)
        return card
    }

    func configureDeleteButton() {
        deleteButton.setTitle("탈퇴하기", for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        deleteButton.backgroundColor = AccountDeletionPalette.danger
        deleteButton.layer.cornerRadius = 12
        deleteButton.accessibilityIdentifier = "account-deletion-submit"
        deleteButton.addAction(UIAction { [weak self] _ in self?.confirmDeletion() }, for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)
        buttonBottomConstraint = deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -AppStyle.bottomActionSafeInset)
        buttonBelowCardConstraint = deleteButton.topAnchor.constraint(equalTo: passwordCard.bottomAnchor, constant: 16)
        scrollBottomToButton = scrollView.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -16)
        scrollBottomToKeyboard = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            buttonBottomConstraint, scrollBottomToButton
        ].compactMap { $0 })
    }
}

@MainActor
private extension AccountDeletionViewController {
    func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
