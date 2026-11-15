import UIKit

@MainActor
final class CommunityReportFlowViewController: UIViewController, UIGestureRecognizerDelegate {
    private let reasons = ["욕설·비방", "도배·광고", "개인정보 노출", "부적절한 내용", "기타"]
    private var selectedReason = "도배·광고"
    private let dimView = UIView()
    private let sheetView = UIView()
    private let contentStack = UIStackView()
    private var bottomConstraint: NSLayoutConstraint?
    private var isComplete = false

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
        let title = AppStyle.label("신고 사유 선택", size: 18, weight: .bold)
        let helper = AppStyle.label("신고한 사람의 정보는 공개되지 않아요.", size: 13, color: AppStyle.muted)
        let rows = UIStackView()
        rows.axis = .vertical
        for (index, reason) in reasons.enumerated() {
            rows.addArrangedSubview(makeReasonRow(reason))
            if index < reasons.count - 1 { rows.addArrangedSubview(makeDivider()) }
        }
        let submit = AppStyle.button("신고하기", primary: true) { [weak self] in
            self?.showCompletion()
        }
        submit.accessibilityIdentifier = "community-report-submit"
        submit.heightAnchor.constraint(equalToConstant: 52).isActive = true
        let indicator = makeHomeIndicator()
        replaceContent([handle, title, helper, rows, submit, indicator], spacing: 16,
            insets: NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 0, trailing: 24))
    }

    private func showCompletion() {
        guard !isComplete else { return }
        isComplete = true
        let handle = makeHandle()
        let icon = UIImageView(image: UIImage(named: "CommunityReportDoneCheck")?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.backgroundColor = AppStyle.paleBlue
        icon.layer.cornerRadius = 32
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 64)
        ])

        let title = AppStyle.label("신고가 접수됐어요", size: 20, weight: .bold)
        let text = title.text ?? "신고가 접수됐어요"
        let attributed = NSMutableAttributedString(string: text, attributes: [.foregroundColor: AppStyle.ink])
        if let range = text.range(of: "접수됐어요") {
            attributed.addAttribute(.foregroundColor, value: AppStyle.blue, range: NSRange(range, in: text))
        }
        title.attributedText = attributed
        title.textAlignment = .center
        title.accessibilityIdentifier = "community-report-complete-title"
        let helper = AppStyle.label(
            "운영자가 확인한 뒤 조치할게요.\n신고자 정보는 공개되지 않아요.",
            size: 14,
            color: AppStyle.muted
        )
        helper.textAlignment = .center
        let close = AppStyle.button("확인", primary: true) { [weak self] in self?.dismissSheet() }
        close.accessibilityIdentifier = "community-report-complete-confirm"
        close.heightAnchor.constraint(equalToConstant: 52).isActive = true
        let indicator = makeHomeIndicator()
        view.layoutIfNeeded()
        replaceContent(
            [handle, icon, title, helper, close, indicator],
            spacing: 16,
            insets: NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 0, trailing: 24)
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

    private func makeReasonRow(_ reason: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let label = AppStyle.label(reason, size: 15, weight: .medium)
        let radio = UIView()
        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = selectedReason == reason ? 0 : 1
        radio.layer.borderColor = AppStyle.line.cgColor
        radio.backgroundColor = selectedReason == reason ? AppStyle.blue : .white
        radio.translatesAutoresizingMaskIntoConstraints = false
        if selectedReason == reason {
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
        button.accessibilityTraits = selectedReason == reason ? [.button, .selected] : [.button]
        button.accessibilityIdentifier = "community-report-reason-\(reasons.firstIndex(of: reason) ?? 0)"
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.selectedReason = reason
            self.showReasons()
        }, for: .touchUpInside)
        return button
    }

    private func makeHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.widthAnchor.constraint(equalToConstant: 44).isActive = true
        handle.heightAnchor.constraint(equalToConstant: 5).isActive = true
        return handle
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = AppStyle.line
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private func makeHomeIndicator() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 21).isActive = true
        let indicator = UIView()
        indicator.backgroundColor = AppStyle.ink
        indicator.layer.cornerRadius = 2.5
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
