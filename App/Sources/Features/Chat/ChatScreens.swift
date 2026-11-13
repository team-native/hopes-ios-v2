import CoreLocation
import MapKit
import UIKit
import Network

@MainActor
final class QuestionListViewController: AppPageViewController {
    private let category: String

    init(category: String) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = category
        addHeading("\(category) 선배에게 물어보기", subtitle: "질문을 골라 대화를 시작해보세요")
        [
            "이 학과에서는 어떤 걸 배우나요?",
            "수업과 프로젝트는 어떻게 진행되나요?",
            "입학 전에 공부하면 좋은 과목이 있나요?",
            "졸업 후 진로는 어떤가요?"
        ].forEach { question in
            addRow(question, symbol: "bubble.left") { [weak self] in
                self?.push(ChatConversationViewController(question: question))
            }
        }
        contentStack.addArrangedSubview(AppStyle.button("직접 질문하기", primary: true) { [weak self] in
            self?.push(ChatConversationViewController(question: nil))
        })
    }
}

@MainActor
final class ChatConversationViewController: UIViewController, UITextFieldDelegate, @preconcurrency CLLocationManagerDelegate {
    private let initialQuestion: String?
    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let inputField = UITextField()
    private let stopAnswerButton = UIButton(type: .system)
    private let networkMonitor = NWPathMonitor()
    private let locationManager = CLLocationManager()
    private var isLiked = false
    private var generationTimer: DispatchWorkItem?
    private var pendingAnswerCard: UIView?
    private var answerFailureCard: UIView?
    private var offlineBanner: UIView?
    private var pendingStatusRow: UIView?
    private var retryWhenOnline = false
    private var isOffline = false
    private var locationCardTitle: UILabel?
    private var locationCardSubtitle: UILabel?
    private var locationProgress: UIProgressView?
    private var locationCardIcon: UIImageView?
    private var locationMapButton: UIButton?
    private var locationCard: UIView?
    private var measuredLocation: CLLocationCoordinate2D?
    private var measuredLocationAccuracy: CLLocationAccuracy = 15

    init(question: String?) {
        initialQuestion = question
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func startLocationRequestFromHome() {
        loadViewIfNeeded()
        beginLocationMeasurement()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppStyle.canvas
        locationManager.delegate = self
        configureMessages()
        configureComposer()
        observeNetworkStatus()

        if let initialQuestion {
            addConversationHeader()
            addUserMessage(initialQuestion)
            beginAnswerGeneration()
        } else {
            addConversationHeader()
            addMessage("학교생활에 대해 궁금한 점을 편하게 물어보세요", outgoing: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }

    private func configureMessages() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        messagesStack.axis = .vertical
        messagesStack.spacing = 14
        messagesStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(messagesStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            messagesStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 18),
            messagesStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -18),
            messagesStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -18)
        ])

        stopAnswerButton.setTitle("답변 중지", for: .normal)
        stopAnswerButton.setTitleColor(AppStyle.ink, for: .normal)
        stopAnswerButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        stopAnswerButton.backgroundColor = .white
        stopAnswerButton.layer.cornerRadius = 12
        stopAnswerButton.layer.borderWidth = 1
        stopAnswerButton.layer.borderColor = AppStyle.line.cgColor
        stopAnswerButton.contentEdgeInsets = UIEdgeInsets(top: 13, left: 20, bottom: 13, right: 20)
        stopAnswerButton.isHidden = true
        stopAnswerButton.addAction(UIAction { [weak self] _ in self?.stopAnswerGeneration() }, for: .touchUpInside)
        stopAnswerButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopAnswerButton)
        NSLayoutConstraint.activate([
            stopAnswerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopAnswerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -76)
        ])
    }

    private func observeNetworkStatus() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.updateNetworkStatus(isOffline: path.status != .satisfied) }
        }
        networkMonitor.start(queue: DispatchQueue(label: "kr.hs.gsm.hopes.chat-network"))
    }

    private func updateNetworkStatus(isOffline: Bool) {
        guard self.isOffline != isOffline else { return }
        self.isOffline = isOffline
        if isOffline {
            showOfflineBanner()
            inputField.placeholder = "오프라인 상태예요"
            inputField.isEnabled = false
            if generationTimer != nil {
                generationTimer?.cancel()
                generationTimer = nil
                if let pendingAnswerCard {
                    messagesStack.removeArrangedSubview(pendingAnswerCard)
                    pendingAnswerCard.removeFromSuperview()
                    self.pendingAnswerCard = nil
                }
                stopAnswerButton.isHidden = true
                retryWhenOnline = true
                showPendingStatus()
            }
        } else {
            offlineBanner?.removeFromSuperview()
            offlineBanner = nil
            pendingStatusRow?.removeFromSuperview()
            pendingStatusRow = nil
            inputField.placeholder = "추가 질문 입력…"
            inputField.isEnabled = true
            if retryWhenOnline {
                retryWhenOnline = false
                beginAnswerGeneration()
            }
        }
    }

    private func showOfflineBanner() {
        guard offlineBanner == nil else { return }
        let banner = UIStackView()
        banner.axis = .horizontal
        banner.alignment = .center
        banner.spacing = 8
        banner.isLayoutMarginsRelativeArrangement = true
        banner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        banner.backgroundColor = AppStyle.ink
        banner.layer.cornerRadius = 14
        let icon = UIImageView(image: UIImage(systemName: "wifi.slash"))
        icon.tintColor = .white
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("인터넷 연결이 끊겼어요. 연결되면 자동으로 다시 시도해요.", size: 12, color: .white)
        banner.addArrangedSubview(icon)
        banner.addArrangedSubview(message)
        messagesStack.insertArrangedSubview(banner, at: min(1, messagesStack.arrangedSubviews.count))
        offlineBanner = banner
    }

    private func showPendingStatus() {
        guard pendingStatusRow == nil else { return }
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 6
        let clock = UIImageView(image: UIImage(systemName: "clock"))
        clock.tintColor = AppStyle.muted
        clock.widthAnchor.constraint(equalToConstant: 14).isActive = true
        clock.heightAnchor.constraint(equalToConstant: 14).isActive = true
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(clock)
        row.addArrangedSubview(AppStyle.label("연결되면 전송돼요", size: 12, color: AppStyle.muted))
        messagesStack.addArrangedSubview(row)
        pendingStatusRow = row
    }

    private func beginAnswerGeneration() {
        if isOffline {
            retryWhenOnline = true
            showPendingStatus()
            return
        }
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("Frontend 시작 순서", size: 18, weight: .semibold)
        let partial = AppStyle.label("처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요. HTML·CSS로 간단한 페이지를", size: 15)
        let cursor = UIView()
        cursor.backgroundColor = AppStyle.blue
        cursor.widthAnchor.constraint(equalToConstant: 2).isActive = true
        cursor.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let content = UIStackView(arrangedSubviews: [title, partial, cursor])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
        pendingAnswerCard = card
        stopAnswerButton.isHidden = false
        inputField.placeholder = "답변을 만드는 중이에요…"
        inputField.isEnabled = false

        let work = DispatchWorkItem { [weak self] in self?.finishAnswerGeneration() }
        generationTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }

    private func finishAnswerGeneration() {
        generationTimer = nil
        if let pendingAnswerCard {
            messagesStack.removeArrangedSubview(pendingAnswerCard)
            pendingAnswerCard.removeFromSuperview()
            self.pendingAnswerCard = nil
        }
        stopAnswerButton.isHidden = true
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
        addFormattedAnswer()
    }

    private func stopAnswerGeneration() {
        generationTimer?.cancel()
        generationTimer = nil
        stopAnswerButton.isHidden = true
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
        if let pendingAnswerCard {
            messagesStack.removeArrangedSubview(pendingAnswerCard)
            pendingAnswerCard.removeFromSuperview()
            self.pendingAnswerCard = nil
        }
        addAnswerFailure()
    }

    private func addAnswerFailure() {
        let card = UIView()
        let alertIcon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        alertIcon.tintColor = UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1)
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let heading = AppStyle.label("답변을 만들지 못했어요", size: 15, weight: .semibold, color: UIColor(red: 0.94, green: 0.27, blue: 0.35, alpha: 1))
        let headline = UIStackView(arrangedSubviews: [alertIcon, heading])
        headline.axis = .horizontal
        headline.alignment = .center
        headline.spacing = 8
        let detail = AppStyle.label("일시적인 오류예요. 같은 질문으로 다시 시도할 수 있어요.", size: 14, weight: .medium, color: AppStyle.muted)
        let retry = UIButton(type: .system)
        retry.setTitle("다시 시도", for: .normal)
        retry.setTitleColor(AppStyle.muted, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        retry.contentHorizontalAlignment = .leading
        retry.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.messagesStack.removeArrangedSubview(card)
            card.removeFromSuperview()
            self.answerFailureCard = nil
            self.beginAnswerGeneration()
        }, for: .touchUpInside)
        let content = UIStackView(arrangedSubviews: [headline, detail, retry])
        content.axis = .vertical
        content.spacing = 6
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
        answerFailureCard = card
    }

    private func addConversationHeader() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppStyle.ink
        back.widthAnchor.constraint(equalToConstant: 44).isActive = true
        back.heightAnchor.constraint(equalToConstant: 44).isActive = true
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)

        let titleStack = UIStackView(arrangedSubviews: [
            AppStyle.label("전공 공부", size: 18, weight: .semibold),
            AppStyle.label("\(UserDefaults.standard.string(forKey: "chat.selectedDepartment") ?? "소프트웨어개발과") · \(UserDefaults.standard.string(forKey: "chat.selectedMajor") ?? "Frontend")", size: 12, color: AppStyle.muted)
        ])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        let row = UIStackView(arrangedSubviews: [back, titleStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        messagesStack.addArrangedSubview(row)
    }

    private func addUserMessage(_ text: String) {
        let bubble = UIView()
        bubble.backgroundColor = AppStyle.blue
        bubble.layer.cornerRadius = 20
        bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 340).isActive = true
        let label = AppStyle.label(text, size: 15, color: .white)
        let wrapper = UIView()
        wrapper.addSubview(bubble)
        bubble.addSubview(label)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: wrapper.topAnchor),
            bubble.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            bubble.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -12)
        ])
        messagesStack.addArrangedSubview(wrapper)
    }

    private func addFormattedAnswer() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("Frontend 시작 순서", size: 18, weight: .semibold)
        let intro = AppStyle.label("처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요.", size: 15)
        let steps = UIStackView()
        steps.axis = .vertical
        steps.spacing = 4
        ["HTML·CSS로 간단한 페이지 만들기", "JavaScript 기초 문법 익히기", "React로 작은 프로젝트 완성하기"].enumerated().forEach { index, text in
            let number = AppStyle.label("\(index + 1).", size: 15, weight: .semibold, color: AppStyle.blue)
            number.widthAnchor.constraint(equalToConstant: 22).isActive = true
            let row = UIStackView(arrangedSubviews: [number, AppStyle.label(text, size: 15)])
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 8
            steps.addArrangedSubview(row)
        }

        let codeCard = UIView()
        codeCard.backgroundColor = AppStyle.canvas
        codeCard.layer.cornerRadius = 12
        codeCard.layer.borderWidth = 1
        codeCard.layer.borderColor = AppStyle.line.cgColor
        let language = AppStyle.label("html", size: 12, color: AppStyle.muted)
        let copy = UIButton(type: .system)
        copy.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copy.tintColor = AppStyle.muted
        copy.accessibilityLabel = "코드 복사"
        copy.addAction(UIAction { [weak self] _ in
            UIPasteboard.general.string = "<button class=\"primary\">\n  질문하기\n</button>"
            self?.showToast("코드를 복사했어요")
        }, for: .touchUpInside)
        copy.widthAnchor.constraint(equalToConstant: 28).isActive = true
        copy.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let codeHeader = UIStackView(arrangedSubviews: [language, copy])
        codeHeader.axis = .horizontal
        codeHeader.alignment = .center
        let code = AppStyle.label("<button class=\"primary\">\n  질문하기\n</button>", size: 12)
        code.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        let codeStack = UIStackView(arrangedSubviews: [codeHeader, code])
        codeStack.axis = .vertical
        codeStack.spacing = 6
        codeStack.isLayoutMarginsRelativeArrangement = true
        codeStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        codeStack.translatesAutoresizingMaskIntoConstraints = false
        codeCard.addSubview(codeStack)
        NSLayoutConstraint.activate([
            codeStack.topAnchor.constraint(equalTo: codeCard.topAnchor),
            codeStack.leadingAnchor.constraint(equalTo: codeCard.leadingAnchor),
            codeStack.trailingAnchor.constraint(equalTo: codeCard.trailingAnchor),
            codeStack.bottomAnchor.constraint(equalTo: codeCard.bottomAnchor)
        ])

        let quote = AppStyle.label("막히면 선배에게 바로 물어보는 게 제일 빨라요.", size: 14, weight: .medium, color: AppStyle.muted)
        let quoteRow = UIView()
        let quoteLine = UIView()
        quoteLine.backgroundColor = AppStyle.blue.withAlphaComponent(0.45)
        quoteRow.addSubview(quoteLine)
        quoteRow.addSubview(quote)
        quoteLine.translatesAutoresizingMaskIntoConstraints = false
        quote.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quoteLine.leadingAnchor.constraint(equalTo: quoteRow.leadingAnchor),
            quoteLine.topAnchor.constraint(equalTo: quoteRow.topAnchor),
            quoteLine.bottomAnchor.constraint(equalTo: quoteRow.bottomAnchor),
            quoteLine.widthAnchor.constraint(equalToConstant: 3),
            quote.leadingAnchor.constraint(equalTo: quoteLine.trailingAnchor, constant: 10),
            quote.trailingAnchor.constraint(equalTo: quoteRow.trailingAnchor),
            quote.topAnchor.constraint(equalTo: quoteRow.topAnchor, constant: 2),
            quote.bottomAnchor.constraint(equalTo: quoteRow.bottomAnchor, constant: -2)
        ])

        let schoolLink = UIButton(type: .system)
        schoolLink.setTitle("학교 전공 소개 페이지 보기", for: .normal)
        schoolLink.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        schoolLink.contentHorizontalAlignment = .leading
        schoolLink.addAction(UIAction { [weak self] _ in self?.presentMessage("전공 소개 페이지는 서비스 연결 후 열 수 있어요") }, for: .touchUpInside)

        let answer = UIStackView(arrangedSubviews: [title, intro, steps, codeCard, quoteRow, schoolLink])
        answer.axis = .vertical
        answer.spacing = 10
        answer.isLayoutMarginsRelativeArrangement = true
        answer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        answer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(answer)
        NSLayoutConstraint.activate([
            answer.topAnchor.constraint(equalTo: card.topAnchor),
            answer.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            answer.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            answer.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
        addAnswerActions()
        addRelatedQuestions()
    }

    private func addAnswerActions() {
        let like = actionChip("좋아요", symbol: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup", selected: isLiked) { [weak self] in
            guard let self else { return }
            self.isLiked.toggle()
            self.refreshAnswerActions()
        }
        like.accessibilityIdentifier = "answer-like"
        let more = actionChip("더 물어보기", symbol: "bubble.left", selected: true) { [weak self] in
            self?.inputField.becomeFirstResponder()
        }
        let share = actionChip("공유", symbol: "square.and.arrow.up") { [weak self] in self?.shareAnswer() }
        let row = UIStackView(arrangedSubviews: [like, more, share])
        row.axis = .horizontal
        row.spacing = 8
        messagesStack.addArrangedSubview(row)
    }

    private func refreshAnswerActions() {
        guard let row = messagesStack.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.first?.accessibilityIdentifier == "answer-like" }) as? UIStackView,
              let like = row.arrangedSubviews.first as? UIButton else { return }
        let title = isLiked ? "좋아요 · 1" : "좋아요"
        like.setTitle(title, for: .normal)
        like.setImage(UIImage(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"), for: .normal)
        like.backgroundColor = isLiked ? AppStyle.blue : .white
        like.setTitleColor(isLiked ? .white : AppStyle.ink, for: .normal)
        like.tintColor = isLiked ? .white : AppStyle.ink
    }

    private func actionChip(_ title: String, symbol: String, selected: Bool = false, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = selected ? .white : AppStyle.ink
        button.setTitleColor(selected ? .white : AppStyle.ink, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = selected ? AppStyle.blue : .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = AppStyle.line.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func addRelatedQuestions() {
        let card = AppStyle.card()
        let heading = AppStyle.label("추가로 많이 묻는 질문", size: 16, weight: .bold)
        let rows = UIStackView()
        rows.axis = .vertical
        ["포트폴리오는 언제부터 만들었어?", "전공 동아리 들어가려면 뭐 준비해?"].forEach { question in
            let button = UIButton(type: .system)
            button.setTitle("◉  \(question)", for: .normal)
            button.setTitleColor(AppStyle.ink, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15)
            button.contentHorizontalAlignment = .leading
            button.heightAnchor.constraint(equalToConstant: 48).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.addUserMessage(question)
                self?.addMessage("질문을 기록했어요. 실제 답변은 서버 연결 후 표시됩니다.", outgoing: false)
            }, for: .touchUpInside)
            rows.addArrangedSubview(button)
        }
        let content = UIStackView(arrangedSubviews: [heading, rows])
        content.axis = .vertical
        content.spacing = 4
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
    }

    private func configureComposer() {
        let composer = UIStackView()
        composer.axis = .horizontal
        composer.spacing = 10
        composer.alignment = .center
        composer.backgroundColor = .white
        composer.layer.cornerRadius = 28
        composer.layer.borderWidth = 1
        composer.layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        composer.layer.shadowColor = UIColor(red: 26 / 255.0, green: 64 / 255.0, blue: 128 / 255.0, alpha: 0.09).cgColor
        composer.layer.shadowOpacity = 1
        composer.layer.shadowRadius = 14
        composer.layer.shadowOffset = CGSize(width: 0, height: 8)
        composer.isLayoutMarginsRelativeArrangement = true
        composer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        composer.translatesAutoresizingMaskIntoConstraints = false

        inputField.placeholder = "추가 질문 입력…"
        inputField.borderStyle = .none
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let attach = UIButton(type: .system)
        attach.setImage(UIImage(named: "map-composer-plus"), for: .normal)
        attach.tintColor = LocationMapStyle.ink
        attach.backgroundColor = .white
        attach.layer.cornerRadius = 20
        attach.layer.borderWidth = 1
        attach.layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        attach.widthAnchor.constraint(equalToConstant: 40).isActive = true
        attach.heightAnchor.constraint(equalToConstant: 40).isActive = true
        attach.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let picker = ChatAttachmentPickerViewController()
            picker.onAttachmentSelected = { [weak self] fileName, image in
                guard let self else { return }
                let preview = ChatAttachmentPreviewViewController(fileName: fileName, image: image)
                preview.onSend = { [weak self] in self?.addMessage("첨부했어요: \(fileName)", outgoing: true) }
                self.present(preview, animated: true)
            }
            picker.onLocationRequested = { [weak self] in
                self?.beginLocationMeasurement()
            }
            self.present(picker, animated: true)
        }, for: .touchUpInside)
        let send = UIButton(type: .system)
        send.setImage(UIImage(named: "map-composer-up"), for: .normal)
        send.tintColor = .white
        send.backgroundColor = LocationMapStyle.brand
        send.layer.cornerRadius = 20
        send.addAction(UIAction { [weak self] _ in self?.sendMessage() }, for: .touchUpInside)
        send.widthAnchor.constraint(equalToConstant: 40).isActive = true
        send.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let mic = UIButton(type: .system)
        mic.setImage(UIImage(named: "map-composer-mic"), for: .normal)
        mic.tintColor = LocationMapStyle.secondary
        mic.widthAnchor.constraint(equalToConstant: 40).isActive = true
        mic.heightAnchor.constraint(equalToConstant: 40).isActive = true
        mic.addAction(UIAction { [weak self] _ in self?.presentMessage("음성 입력은 추후 지원할 예정이에요") }, for: .touchUpInside)
        composer.addArrangedSubview(attach)
        composer.addArrangedSubview(inputField)
        composer.addArrangedSubview(mic)
        composer.addArrangedSubview(send)
        view.addSubview(composer)

        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            composer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            composer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            composer.heightAnchor.constraint(equalToConstant: 52),
            scrollView.bottomAnchor.constraint(equalTo: composer.topAnchor),
            inputField.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }

    private func beginLocationMeasurement(isRetry: Bool = false) {
        if !isRetry { addUserMessage("지금 내 위치 알려줘") }
        let card = makeLocationMeasurementCard()
        if isRetry {
            replaceLocationCard(with: card)
        } else {
            messagesStack.addArrangedSubview(card)
            locationCard = card
        }
        scrollToLatestMessage()

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            updateLocationMeasurement(
                title: "위치 권한이 필요해요",
                subtitle: "설정에서 위치 접근을 허용한 뒤 다시 시도해 주세요.",
                progress: 1
            )
        @unknown default:
            updateLocationMeasurement(
                title: "위치를 확인할 수 없어요",
                subtitle: "위치 설정을 확인한 뒤 다시 시도해 주세요.",
                progress: 1
            )
        }
    }

    private func makeLocationMeasurementCard() -> UIView {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let iconContainer = UIView()
        iconContainer.backgroundColor = AppStyle.paleBlue
        iconContainer.layer.cornerRadius = 12
        iconContainer.widthAnchor.constraint(equalToConstant: 44).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let pinPath = Bundle.main.path(forResource: "chat-location-pin", ofType: "png")
        let pin = UIImageView(image: pinPath.flatMap(UIImage.init(contentsOfFile:)))
        pin.contentMode = .scaleAspectFit
        pin.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 24),
            pin.heightAnchor.constraint(equalToConstant: 24)
        ])
        locationCardIcon = pin

        let title = AppStyle.label("현재 위치를 확인하고 있어요…", size: 15, weight: .medium)
        let subtitle = AppStyle.label("잠시만 기다려 주세요. 보통 몇 초면 끝나요.", size: 12, color: AppStyle.muted)
        subtitle.numberOfLines = 1
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 2
        let row = UIStackView(arrangedSubviews: [iconContainer, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0.42
        progress.progressTintColor = AppStyle.blue
        progress.trackTintColor = UIColor(red: 0.90, green: 0.94, blue: 0.99, alpha: 1)
        progress.layer.cornerRadius = 3
        progress.clipsToBounds = true
        progress.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let mapButton = UIButton(type: .system)
        var mapConfiguration = UIButton.Configuration.filled()
        mapConfiguration.title = "지도 보기"
        mapConfiguration.baseBackgroundColor = AppStyle.paleBlue
        mapConfiguration.baseForegroundColor = AppStyle.blue
        mapConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        mapButton.configuration = mapConfiguration
        mapButton.layer.cornerRadius = 10
        mapButton.clipsToBounds = true
        mapButton.isHidden = true
        mapButton.addAction(UIAction { [weak self] _ in self?.openMeasuredLocationInMaps() }, for: .touchUpInside)
        locationMapButton = mapButton

        let content = UIStackView(arrangedSubviews: [row, progress, mapButton])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        locationCardTitle = title
        locationCardSubtitle = subtitle
        locationProgress = progress
        return card
    }

    private func updateLocationMeasurement(title: String, subtitle: String, progress: Float, isOutsideSchool: Bool = false) {
        locationCardTitle?.text = title
        locationCardSubtitle?.text = subtitle
        locationProgress?.setProgress(progress, animated: true)
        if isOutsideSchool {
            let infoPath = Bundle.main.path(forResource: "outside-school-info", ofType: "png")
            locationCardIcon?.image = infoPath.flatMap(UIImage.init(contentsOfFile:))
            locationProgress?.isHidden = true
            locationMapButton?.isHidden = false
        }
        scrollToLatestMessage()
    }

    private func replaceLocationCard(with card: UIView) {
        if let locationCard, let index = messagesStack.arrangedSubviews.firstIndex(of: locationCard) {
            messagesStack.removeArrangedSubview(locationCard)
            locationCard.removeFromSuperview()
            messagesStack.insertArrangedSubview(card, at: index)
        } else {
            messagesStack.addArrangedSubview(card)
        }
        locationCard = card
    }

    private func openSchoolMap() {
        guard navigationController != nil else { return }
        let map = ChatLocationViewController(accuracy: measuredLocationAccuracy)
        navigationController?.pushViewController(map, animated: true)
    }

    private func makeLowAccuracyCard(accuracy: CLLocationAccuracy) -> UIView {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("학교 근처로 보이지만 위치 정확도가 낮아요.", size: 15)
        let warning = UIStackView()
        warning.axis = .horizontal
        warning.alignment = .center
        warning.spacing = 8
        warning.isLayoutMarginsRelativeArrangement = true
        warning.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        warning.backgroundColor = UIColor(red: 1, green: 0.94, blue: 0.95, alpha: 1)
        warning.layer.cornerRadius = 16
        let alertPath = Bundle.main.path(forResource: "location-low-accuracy-alert", ofType: "png")
        let alertIcon = UIImageView(image: alertPath.flatMap(UIImage.init(contentsOfFile:)))
        alertIcon.contentMode = .scaleAspectFit
        alertIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        alertIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        let accuracyLabel = AppStyle.label(
            "정확도 약 ±\(Int(accuracy.rounded()))m · 실내에서는 오차가 커질 수 있어요.",
            size: 12,
            color: AppStyle.muted
        )
        accuracyLabel.numberOfLines = 1
        warning.addArrangedSubview(alertIcon)
        warning.addArrangedSubview(accuracyLabel)

        let retryButton = UIButton(type: .system)
        var retryConfiguration = UIButton.Configuration.plain()
        retryConfiguration.title = "다시 측정"
        retryConfiguration.baseForegroundColor = AppStyle.blue
        retryConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        retryButton.configuration = retryConfiguration
        retryButton.backgroundColor = .white
        retryButton.layer.cornerRadius = 10
        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor
        retryButton.addAction(UIAction { [weak self] _ in
            self?.beginLocationMeasurement(isRetry: true)
        }, for: .touchUpInside)

        let mapButton = UIButton(type: .system)
        var mapConfiguration = UIButton.Configuration.filled()
        mapConfiguration.title = "지도 보기"
        mapConfiguration.baseBackgroundColor = AppStyle.paleBlue
        mapConfiguration.baseForegroundColor = AppStyle.blue
        mapConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        mapButton.configuration = mapConfiguration
        mapButton.layer.cornerRadius = 10
        mapButton.clipsToBounds = true
        mapButton.addAction(UIAction { [weak self] _ in self?.openMeasuredLocationInMaps() }, for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [retryButton, mapButton])
        buttons.axis = .horizontal
        buttons.spacing = 8
        buttons.distribution = .fillEqually

        let content = UIStackView(arrangedSubviews: [title, warning, buttons])
        content.axis = .vertical
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 14, bottom: 14, trailing: 14)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            updateLocationMeasurement(
                title: "위치 권한이 필요해요",
                subtitle: "설정에서 위치 접근을 허용한 뒤 다시 시도해 주세요.",
                progress: 1
            )
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        measuredLocation = location.coordinate
        measuredLocationAccuracy = location.horizontalAccuracy
        let schoolLocation = CLLocation(latitude: 35.142829306650874, longitude: 126.80021878005266)
        let distanceInMeters = schoolLocation.distance(from: location)
        if distanceInMeters > 250 {
            let distanceText = distanceInMeters >= 1_000
                ? String(format: "%.1fkm", distanceInMeters / 1_000)
                : "\(Int(distanceInMeters.rounded()))m"
            updateLocationMeasurement(
                title: "지금은 학교에서 약 \(distanceText) 떨어진 곳에 있어요.",
                subtitle: "학교 안에서는 건물 기준으로 더 자세히 안내해 드려요.",
                progress: 1,
                isOutsideSchool: true
            )
            return
        }
        if location.horizontalAccuracy > 100 {
            let card = makeLowAccuracyCard(accuracy: location.horizontalAccuracy)
            replaceLocationCard(with: card)
            scrollToLatestMessage()
            return
        }
        let result = ChatLocationResultCardView(accuracy: location.horizontalAccuracy) { [weak self] in
            self?.openSchoolMap()
        }
        replaceLocationCard(with: result)
        scrollToLatestMessage()
    }

    private func openMeasuredLocationInMaps() {
        guard let measuredLocation else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: measuredLocation))
        item.name = "현재 위치"
        item.openInMaps(launchOptions: [MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue])
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        updateLocationMeasurement(
            title: "위치를 확인하지 못했어요",
            subtitle: "잠시 후 다시 시도해 주세요.",
            progress: 1
        )
    }

    private func scrollToLatestMessage() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let bottom = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height))
            self.scrollView.setContentOffset(bottom, animated: true)
        }
    }

    private func addMessage(_ text: String, outgoing: Bool) {
        let bubble = UIView()
        bubble.backgroundColor = outgoing ? AppStyle.paleBlue : .white
        bubble.layer.cornerRadius = 16
        let label = AppStyle.label(text, size: 15, color: AppStyle.ink)
        label.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 13),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -15),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -13),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])

        let spacer = UIView()
        let line = UIStackView(arrangedSubviews: outgoing ? [spacer, bubble] : [bubble, spacer])
        line.axis = .horizontal
        line.alignment = .top
        line.distribution = .fill
        messagesStack.addArrangedSubview(line)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let bottom = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height))
            self.scrollView.setContentOffset(bottom, animated: true)
        }
    }

    private func shareAnswer() {
        let activity = UIActivityViewController(activityItems: ["Frontend 시작 순서\nHTML·CSS로 간단한 페이지 만들기 → JavaScript 기초 문법 익히기 → React로 작은 프로젝트 완성하기"], applicationActivities: nil)
        present(activity, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak alert] in alert?.dismiss(animated: true) }
    }

    private func presentMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func sendMessage() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        inputField.text = nil
        addMessage(text, outgoing: true)
        beginAnswerGeneration()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
