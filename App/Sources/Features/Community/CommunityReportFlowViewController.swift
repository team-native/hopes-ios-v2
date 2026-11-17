import UIKit

@MainActor
final class CommunityReportFlowViewController: UIViewController, UIGestureRecognizerDelegate {
    private let reasons = ["욕설·비방", "도배·광고", "개인정보 노출", "부적절한 내용", "기타"]
    private var selectedReason = "도배·광고"
    private let dimView = UIView()
    private let sheetView = UIView()
    private let contentStack = UIStackView()
    private let onSubmit: (String) -> Void
    private let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    private let primaryText = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    private let secondaryText = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    private let subtleBorder = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    private let defaultBorder = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
    private var bottomConstraint: NSLayoutConstraint?
    private var isComplete = false

    init(onSubmit: @escaping (String) -> Void = { _ in }) {
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "community-report-flow-sheet"
        view.backgroundColor = .clear
        configureDimView()
        configureSheet()
        showReasons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomConstraint?.constant = -6
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    private func configureDimView() {
        dimView.backgroundColor = UIColor(red: 20 / 255, green: 28 / 255, blue: 43 / 255, alpha: 0.32)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        tap.delegate = self
        dimView.addGestureRecognizer(tap)
    }

    private func configureSheet() {
        sheetView.backgroundColor = .white
        sheetView.layer.cornerRadius = 28
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(contentStack)
        let bottom = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 480)
        bottomConstraint = bottom
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor), bottom,
            contentStack.topAnchor.constraint(equalTo: sheetView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor)
        ])
        sheetView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    private func showReasons() {
        isComplete = false
        let handle = makeHandle()
        let title = AppStyle.label("신고 사유 선택", size: 22, weight: .bold, color: primaryText)
        title.attributedText = NSAttributedString(string: "신고 사유 선택", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: primaryText,
            .kern: -0.3,
            .paragraphStyle: makeLineStyle(height: 30)
        ])
        title.heightAnchor.constraint(equalToConstant: 30).isActive = true
        let helperText = "신고한 사람의 정보는 공개되지 않아요."
        let helper = AppStyle.label(helperText, size: 14, weight: .medium, color: secondaryText)
        helper.attributedText = NSAttributedString(string: helperText, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: secondaryText,
            .paragraphStyle: makeLineStyle(height: 20)
        ])
        helper.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let rows = UIStackView()
        rows.axis = .vertical
        for (index, reason) in reasons.enumerated() {
            rows.addArrangedSubview(makeReasonRow(reason))
            if index < reasons.count - 1 { rows.addArrangedSubview(makeDivider()) }
        }
        let submit = makePrimaryButton(title: "신고하기") { [weak self] in self?.showCompletion() }
        submit.accessibilityIdentifier = "community-report-submit"
        let indicator = makeHomeIndicator()
        replaceContent([handle, title, helper, rows, submit, indicator], spacing: 16,
            insets: NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20))
    }

    private func makePrimaryButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = brandBlue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        button.configuration = configuration
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func showCompletion() {
        guard !isComplete else { return }
        isComplete = true
        onSubmit(Self.reasonCode(for: selectedReason))
        let handle = makeHandle()
        let doneContent = makeCompletionContent()
        let close = makePrimaryButton(title: "확인") { [weak self] in self?.dismissSheet() }
        close.accessibilityIdentifier = "community-report-complete-confirm"
        let indicator = makeHomeIndicator()
        view.layoutIfNeeded()
        replaceContent(
            [handle, doneContent, close, indicator],
            spacing: 16,
            insets: NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20)
        )
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }

    private func replaceContent(_ views: [UIView], spacing: CGFloat, insets: NSDirectionalEdgeInsets) {
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentStack.spacing = spacing
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = insets
        views.forEach(contentStack.addArrangedSubview)
    }

    private func makeHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.widthAnchor.constraint(equalToConstant: 44).isActive = true
        handle.heightAnchor.constraint(equalToConstant: 5).isActive = true
        return handle
    }

    private func makeHomeIndicator() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 21).isActive = true
        let indicator = UIView()
        indicator.backgroundColor = AppStyle.ink
        indicator.layer.cornerRadius = 2.5
        indicator.isHidden = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 136),
            indicator.heightAnchor.constraint(equalToConstant: 5),
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view?.isDescendant(of: sheetView) != true
    }

    @objc private func dismissSheet() {
        bottomConstraint?.constant = sheetView.bounds.height + 24
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in self?.dismiss(animated: false) }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view).y
        switch gesture.state {
        case .changed: bottomConstraint?.constant = -6 + max(0, translation)
        case .ended, .cancelled:
            if translation > 80 { dismissSheet() } else {
                bottomConstraint?.constant = -6
                UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
            }
        default: break
        }
    }
}

private extension CommunityReportFlowViewController {
    func makeReasonRow(_ reason: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        let selected = selectedReason == reason
        let label = AppStyle.label(reason, size: 15, weight: selected ? .medium : .regular,
            color: selected ? brandBlue : primaryText)
        label.attributedText = NSAttributedString(string: reason, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: selected ? .medium : .regular),
            .foregroundColor: selected ? brandBlue : primaryText,
            .kern: -0.1,
            .paragraphStyle: makeLineStyle(height: 24)
        ])
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let radio = UIView()
        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = selected ? 0 : 1
        radio.layer.borderColor = defaultBorder.cgColor
        radio.backgroundColor = selected ? brandBlue : .white
        radio.translatesAutoresizingMaskIntoConstraints = false
        if selected { addCheckIcon(to: radio) }
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        button.addSubview(radio)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            radio.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            radio.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            radio.widthAnchor.constraint(equalToConstant: 22),
            radio.heightAnchor.constraint(equalToConstant: 22)
        ])
        button.accessibilityLabel = reason
        button.accessibilityTraits = selected ? [.button, .selected] : [.button]
        button.accessibilityIdentifier = "community-report-reason-\(reasons.firstIndex(of: reason) ?? 0)"
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.selectedReason = reason
            self.showReasons()
        }, for: .touchUpInside)
        return button
    }

    private func addCheckIcon(to radio: UIView) {
        let image = UIImage(named: "CommunityReportRadioCheck")?.withRenderingMode(.alwaysOriginal)
        let check = UIImageView(image: image)
        check.translatesAutoresizingMaskIntoConstraints = false
        radio.addSubview(check)
        NSLayoutConstraint.activate([
            check.widthAnchor.constraint(equalToConstant: 14),
            check.heightAnchor.constraint(equalToConstant: 14),
            check.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: radio.centerYAnchor)
        ])
    }

    func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = subtleBorder
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    func makeLineStyle(height: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = height
        style.maximumLineHeight = height
        return style
    }

    private func makeCompletionContent() -> UIView {
        let icon = UIImageView(image: UIImage(named: "CommunityReportDoneCheck")?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        icon.layer.cornerRadius = 32
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let title = makeCompletionTitle()
        let helper = makeCompletionHelper()
        let doneContent = UIView()
        [icon, title, helper].forEach(doneContent.addSubview)
        doneContent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneContent.heightAnchor.constraint(equalToConstant: 170),
            icon.topAnchor.constraint(equalTo: doneContent.topAnchor, constant: 8),
            icon.centerXAnchor.constraint(equalTo: doneContent.centerXAnchor),
            title.topAnchor.constraint(equalTo: doneContent.topAnchor, constant: 84),
            title.centerXAnchor.constraint(equalTo: doneContent.centerXAnchor),
            helper.topAnchor.constraint(equalTo: doneContent.topAnchor, constant: 126),
            helper.leadingAnchor.constraint(equalTo: doneContent.leadingAnchor),
            helper.trailingAnchor.constraint(equalTo: doneContent.trailingAnchor)
        ])
        return doneContent
    }

    private func makeCompletionTitle() -> UILabel {
        let title = AppStyle.label("신고가 접수됐어요", size: 20, weight: .bold, color: primaryText)
        let text = title.text ?? "신고가 접수됐어요"
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: primaryText,
            .paragraphStyle: makeLineStyle(height: 30)
        ])
        if let range = text.range(of: "접수됐어요") {
            attributed.addAttribute(.foregroundColor, value: brandBlue, range: NSRange(range, in: text))
        }
        title.attributedText = attributed
        title.textAlignment = .center
        title.accessibilityIdentifier = "community-report-complete-title"
        title.translatesAutoresizingMaskIntoConstraints = false
        title.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return title
    }

    private func makeCompletionHelper() -> UILabel {
        let helper = AppStyle.label(
            "운영자가 확인한 뒤 조치할게요.\n신고자 정보는 공개되지 않아요.",
            size: 14,
            color: secondaryText
        )
        helper.textAlignment = .center
        let helperText = helper.text ?? ""
        helper.attributedText = NSAttributedString(string: helperText, attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: secondaryText,
            .paragraphStyle: makeLineStyle(height: 20)
        ])
        helper.translatesAutoresizingMaskIntoConstraints = false
        helper.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return helper
    }

}

extension CommunityReportFlowViewController {
    static func reasonCode(for reason: String) -> String {
        switch reason {
        case "욕설·비방": "ABUSE"
        case "도배·광고": "SPAM"
        case "개인정보 노출": "PRIVACY"
        default: "OTHER"
        }
    }
}
