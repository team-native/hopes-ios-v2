import UIKit

enum ChatHomeRecommendationState {
    case ready
    case loading
    case failed
}

@MainActor
final class ChatHomeViewController: AppPageViewController, UITextFieldDelegate {
    let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)

    let departmentChip = UIButton(type: .system)
    let majorChip = UIButton(type: .system)
    let questionList = UIStackView()
    let infoBanner = UIView()
    let recommendationFailureNotice = UIView()
    var promptTitleView: UIView?
    var refreshSlot: UIView?
    weak var recommendationTitleLabel: UILabel?
    let composerBar = UIView()
    let messageField = UITextField()
    let keyboardHint = AppStyle.label("추천 질문을 누르면 입력창에 채워져요", size: 12,
        color: UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1))
    var hiddenStatesBeforeKeyboard: [ObjectIdentifier: Bool] = [:]
    var selectedDepartment: String?
    var selectedMajor: String?
    var recommendationState: ChatHomeRecommendationState = .ready
    var questionSetIndex = 0
    var recommendationRequestID = 0
    var recommendationRefreshToken: String?
    var shownRecommendationIDs: [Int64] = []

    var questionSets: [[(String, String)]] = [
        [
            ("chat-question-bed-icon", "기숙사 하루 일과가 어떻게 돼?"),
            ("chat-question-file-icon", "입학하려면 뭘 준비해야 해?"),
            ("chat-question-code-icon", "Frontend는 뭐부터 공부하면 좋아?"),
            ("chat-question-heart-icon", "후배한테 해주고 싶은 조언 있어?")
        ],
        [
            ("chat-question-code-icon", "처음 만드는 프로젝트는 어떤 게 좋아?"),
            ("chat-question-bed-icon", "기숙사 생활에 필요한 준비물이 뭐야?"),
            ("chat-question-file-icon", "입학 전에 공부하면 좋은 과목이 있어?"),
            ("chat-question-heart-icon", "학교생활에서 가장 기억에 남는 일은 뭐야?")
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedDepartment = Self.loadContextValue(key: "chat.selectedDepartment", defaultValue: "소프트웨어개발과")
        selectedMajor = Self.loadContextValue(key: "chat.selectedMajor", defaultValue: "Frontend")
        title = nil
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addContextHeader()
        addInfoBanner()
        addPromptTitle()
        addRecommendationHeader()
        configureRecommendationFailureNotice()
        configureQuestionList()
        configureComposer()
        if let bottomConstraint = view.constraints.first(where: {
            $0.firstItem === scrollView && $0.firstAttribute == .bottom
        }) {
            bottomConstraint.isActive = false
        }
        scrollView.bottomAnchor.constraint(equalTo: composerBar.topAnchor, constant: -16).isActive = true
        renderQuestions()
        if AccessTokenStore.shared.hasToken {
            Task { [weak self] in
                await CatalogAPI.refreshCatalogs()
                self?.loadRecommendations()
            }
        }
        view.accessibilityIdentifier = "chat-home-screen"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = false
        updateContextChipTitles()
        observeKeyboardCollapse()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingKeyboardCollapse()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addContextHeader() {
        configureChip(departmentChip, identifier: "chat-department-chip", action: #selector(selectDepartment))
        configureChip(majorChip, identifier: "chat-major-chip", action: #selector(selectMajor))

        let chips = UIStackView(arrangedSubviews: [departmentChip, majorChip])
        chips.axis = .horizontal
        chips.alignment = .center
        chips.spacing = 6
        chips.setContentCompressionResistancePriority(.required, for: .horizontal)

        let newChat = UIButton(type: .system)
        newChat.translatesAutoresizingMaskIntoConstraints = false
        var configuration = UIButton.Configuration.plain()
        configuration.title = "새 대화"
        configuration.baseForegroundColor = brandBlue
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.background.backgroundColor = .white
        configuration.background.strokeColor = line
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 10
        newChat.configuration = configuration
        newChat.addTarget(self, action: #selector(startNewConversation), for: .touchUpInside)
        newChat.accessibilityIdentifier = "chat-new-conversation"
        NSLayoutConstraint.activate([newChat.heightAnchor.constraint(equalToConstant: 38)])

        let header = UIStackView(arrangedSubviews: [chips, UIView(), newChat])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        contentStack.addArrangedSubview(header)
    }

    private func configureChip(_ button: UIButton, identifier: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = brandBlue
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .medium)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        configuration.background.backgroundColor = softBlue
        configuration.background.strokeColor = UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 16
        button.configuration = configuration
        button.accessibilityIdentifier = identifier
        button.addTarget(self, action: action, for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    private func addRecommendationHeader() {
        let title = UILabel()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textColor = secondary
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(named: "chat-refresh-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        refresh.imageView?.contentMode = .scaleAspectFit
        refresh.accessibilityLabel = "추천 질문 새로고침"
        refresh.accessibilityIdentifier = "chat-refresh-questions"
        refresh.addTarget(self, action: #selector(refreshQuestions), for: .touchUpInside)
        refresh.imageView?.contentMode = .scaleAspectFit
        let refreshSlot = UIView()
        refreshSlot.translatesAutoresizingMaskIntoConstraints = false
        refresh.translatesAutoresizingMaskIntoConstraints = false
        refreshSlot.addSubview(refresh)
        NSLayoutConstraint.activate([
            refreshSlot.widthAnchor.constraint(equalToConstant: 18),
            refreshSlot.heightAnchor.constraint(equalToConstant: 20),
            refresh.centerXAnchor.constraint(equalTo: refreshSlot.centerXAnchor),
            refresh.centerYAnchor.constraint(equalTo: refreshSlot.centerYAnchor),
            refresh.widthAnchor.constraint(equalToConstant: 44),
            refresh.heightAnchor.constraint(equalToConstant: 44)
        ])

        let header = UIStackView(arrangedSubviews: [title, UIView(), refreshSlot])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 4
        contentStack.addArrangedSubview(header)
        recommendationTitleLabel = title
        self.refreshSlot = refreshSlot
        updateRecommendationTitle()
    }

    private func configureQuestionList() {
        questionList.axis = .vertical
        questionList.spacing = 8
        contentStack.addArrangedSubview(questionList)
    }

    func renderQuestions() {
        questionList.arrangedSubviews.forEach {
            questionList.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard selectedDepartment != nil, selectedMajor != nil else {
            recommendationState = .ready
            recommendationFailureNotice.isHidden = true
            recommendationTitleLabel?.text = "기본 추천 질문"
            infoBanner.isHidden = false
            promptTitleView?.isHidden = true
            refreshSlot?.isHidden = true
            questionList.addArrangedSubview(makeBasicQuestionList())
            return
        }
        infoBanner.isHidden = true
        promptTitleView?.isHidden = recommendationState == .loading
        refreshSlot?.isHidden = recommendationState == .loading
        recommendationFailureNotice.isHidden = recommendationState != .failed

        switch recommendationState {
        case .loading:
            recommendationTitleLabel?.text = "\(selectedDepartment ?? "") · \(selectedMajor ?? "") 추천 질문 불러오는 중…"
            questionList.addArrangedSubview(makeRecommendationSkeleton())
            return
        case .failed:
            recommendationTitleLabel?.text = "기본 추천 질문"
            for (iconName, question) in questionSets[0].prefix(3) {
                questionList.addArrangedSubview(makeQuestionCard(iconName: iconName, question: question))
            }
            return
        case .ready:
            break
        }
        for (iconName, question) in questionSets[questionSetIndex] {
            questionList.addArrangedSubview(makeQuestionCard(iconName: iconName, question: question))
        }
    }

    func showRecommendationState(_ state: ChatHomeRecommendationState) {
        recommendationState = state
        updateRecommendationTitle()
    }

    @objc private func startNewConversation() {
        navigationController?.pushViewController(ChatConversationViewController(question: nil), animated: true)
    }

    @objc func sendMessage() {
        let question = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !question.isEmpty else { return }
        messageField.text = nil
        messageField.resignFirstResponder()
        navigationController?.pushViewController(ChatConversationViewController(question: question), animated: true)
    }

    @objc func openAttachmentPicker() {
        let picker = ChatAttachmentPickerViewController()
        picker.onAttachmentsSelected = { [weak self] attachments in
            self?.navigationController?.pushViewController(
                ChatConversationViewController(question: nil, attachments: attachments),
                animated: true
            )
        }
        present(picker, animated: true)
    }

    @objc func showVoiceInputNotice() {
        let alert = UIAlertController(title: nil, message: "음성 입력은 아직 지원하지 않아요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
