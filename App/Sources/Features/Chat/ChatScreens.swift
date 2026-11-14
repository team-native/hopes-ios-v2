import CoreLocation
import MapKit
import UIKit
import Network

@MainActor
final class ChatConversationViewController: UIViewController, UITextFieldDelegate,
    @preconcurrency CLLocationManagerDelegate {
    let initialQuestion: String?
    let scrollView = UIScrollView()
    let messagesStack = UIStackView()
    let inputField = UITextField()
    let stopAnswerButton = UIButton(type: .system)
    let networkMonitor = NWPathMonitor()
    let locationManager = CLLocationManager()
    var isLiked = false
    var generationTimer: DispatchWorkItem?
    var pendingAnswerCard: UIView?
    var answerFailureCard: UIView?
    var offlineBanner: UIView?
    var pendingStatusRow: UIView?
    var retryWhenOnline = false
    var isOffline = false
    var locationCard: UIView?
    var measuredLocation: CLLocationCoordinate2D?
    var measuredLocationAccuracy: CLLocationAccuracy = 15
    var hasPendingLocationRequest = false

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

    func configureMessages() {
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
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)
        stopAnswerButton.configuration = buttonConfiguration
        stopAnswerButton.isHidden = true
        stopAnswerButton.addAction(UIAction { [weak self] _ in self?.stopAnswerGeneration() }, for: .touchUpInside)
        stopAnswerButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopAnswerButton)
        NSLayoutConstraint.activate([
            stopAnswerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopAnswerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -76)
        ])
    }

    func configureComposer() {
        let composer = makeComposerContainer()
        let attach = makeAttachmentButton()
        let send = makeSendButton()
        let mic = makeVoiceButton()
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

    private func makeComposerContainer() -> UIStackView {
        let composer = UIStackView()
        composer.axis = .horizontal
        composer.spacing = 10
        composer.alignment = .center
        composer.backgroundColor = .white
        composer.layer.cornerRadius = 28
        composer.layer.borderWidth = 1
        composer.layer.borderColor = LocationMapStyle.subtleBorder.cgColor
        composer.layer.shadowColor = UIColor(
            red: 26 / 255.0,
            green: 64 / 255.0,
            blue: 128 / 255.0,
            alpha: 0.09
        ).cgColor
        composer.layer.shadowOpacity = 1
        composer.layer.shadowRadius = 14
        composer.layer.shadowOffset = CGSize(width: 0, height: 8)
        composer.isLayoutMarginsRelativeArrangement = true
        composer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        configureInputField()
        composer.translatesAutoresizingMaskIntoConstraints = false
        return composer
    }

    private func configureInputField() {
        inputField.placeholder = "추가 질문 입력…"
        inputField.borderStyle = .none
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputField.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    private func makeAttachmentButton() -> UIButton {
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
        return attach
    }

    private func makeSendButton() -> UIButton {
        let send = UIButton(type: .system)
        send.setImage(UIImage(named: "map-composer-up"), for: .normal)
        send.tintColor = .white
        send.backgroundColor = LocationMapStyle.brand
        send.layer.cornerRadius = 20
        send.addAction(UIAction { [weak self] _ in self?.sendMessage() }, for: .touchUpInside)
        send.widthAnchor.constraint(equalToConstant: 40).isActive = true
        send.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return send
    }

    private func makeVoiceButton() -> UIButton {
        let mic = UIButton(type: .system)
        mic.setImage(UIImage(named: "map-composer-mic"), for: .normal)
        mic.tintColor = LocationMapStyle.secondary
        mic.widthAnchor.constraint(equalToConstant: 40).isActive = true
        mic.heightAnchor.constraint(equalToConstant: 40).isActive = true
        mic.addAction(UIAction { [weak self] _ in self?.presentMessage("음성 입력은 추후 지원할 예정이에요") }, for: .touchUpInside)
        return mic
    }

    func addMessage(_ text: String, outgoing: Bool) {
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

    func shareAnswer() {
        let answer = "Frontend 시작 순서\nHTML·CSS로 간단한 페이지 만들기 → JavaScript 기초 문법 익히기 → React로 작은 프로젝트 완성하기"
        let activity = UIActivityViewController(activityItems: [answer], applicationActivities: nil)
        present(activity, animated: true)
    }

    func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak alert] in alert?.dismiss(animated: true) }
    }

    func presentMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func sendMessage() {
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
