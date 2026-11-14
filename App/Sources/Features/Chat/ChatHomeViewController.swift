import UIKit

@MainActor
final class ChatHomeViewController: AppPageViewController, UITextFieldDelegate {
    let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)

    private let departmentChip = UIButton(type: .system)
    private let majorChip = UIButton(type: .system)
    private let questionList = UIStackView()
    let composerBar = UIView()
    let messageField = UITextField()
    var selectedDepartment = UserDefaults.standard.string(forKey: "chat.selectedDepartment") ?? "소프트웨어개발과"
    var selectedMajor = UserDefaults.standard.string(forKey: "chat.selectedMajor") ?? "Frontend"
    private var questionSetIndex = 0

    private let questionSets: [[(String, String)]] = [
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
        addPromptTitle()
        addRecommendationHeader()
        configureQuestionList()
        configureComposer()
        if let bottomConstraint = view.constraints.first(where: {
            $0.firstItem === scrollView && $0.firstAttribute == .bottom
        }) {
            bottomConstraint.isActive = false
        }
        scrollView.bottomAnchor.constraint(equalTo: composerBar.topAnchor, constant: -16).isActive = true
        renderQuestions()
        view.accessibilityIdentifier = "chat-home-screen"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = false
        updateContextChipTitles()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addContextHeader() {
        configureChip(departmentChip, identifier: "chat-department-chip", action: #selector(selectDepartment))
        configureChip(majorChip, identifier: "chat-major-chip", action: #selector(selectMajor))

        let chips = UIStackView(arrangedSubviews: [departmentChip, majorChip])
        chips.axis = .horizontal
        chips.alignment = .center
        chips.spacing = 6
        chips.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let newChat = UIButton(type: .system)
        newChat.translatesAutoresizingMaskIntoConstraints = false
        var configuration = UIButton.Configuration.plain()
        configuration.title = "새 대화"
        configuration.baseForegroundColor = ink
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
        NSLayoutConstraint.activate([newChat.heightAnchor.constraint(equalToConstant: 36)])

        let header = UIStackView(arrangedSubviews: [chips, UIView(), newChat])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        contentStack.addArrangedSubview(header)
        updateContextChipTitles()
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
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func updateContextChipTitles() {
        var departmentConfiguration = departmentChip.configuration
        departmentConfiguration?.title = "학과 · \(selectedDepartment)"
        departmentChip.configuration = departmentConfiguration
        var majorConfiguration = majorChip.configuration
        majorConfiguration?.title = "전공 · \(selectedMajor)"
        majorChip.configuration = majorConfiguration
    }

    private func addPromptTitle() {
        let title = "무엇이 궁금한가요?"
        let attributed = NSMutableAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: ink,
            .kern: -0.3
        ])
        if let range = title.range(of: "궁금한") {
            attributed.addAttribute(.foregroundColor, value: brandBlue, range: NSRange(range, in: title))
        }
        let label = UILabel()
        label.attributedText = attributed
        label.textAlignment = .center
        label.numberOfLines = 1

        let wrapper = UIView()
        label.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -6)
        ])
        contentStack.addArrangedSubview(wrapper)
    }

    private func addRecommendationHeader() {
        let title = UILabel()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textColor = secondary
        title.numberOfLines = 1
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(named: "chat-refresh-icon"), for: .normal)
        refresh.imageView?.contentMode = .scaleAspectFit
        refresh.accessibilityLabel = "추천 질문 새로고침"
        refresh.accessibilityIdentifier = "chat-refresh-questions"
        refresh.addTarget(self, action: #selector(refreshQuestions), for: .touchUpInside)
        refresh.imageView?.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            refresh.widthAnchor.constraint(equalToConstant: 32),
            refresh.heightAnchor.constraint(equalToConstant: 32)
        ])

        let header = UIStackView(arrangedSubviews: [title, UIView(), refresh])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 4
        contentStack.addArrangedSubview(header)
        recommendationTitleLabel = title
        updateRecommendationTitle()
    }

    private weak var recommendationTitleLabel: UILabel?

    func updateRecommendationTitle() {
        recommendationTitleLabel?.text = "\(selectedDepartment) · \(selectedMajor) 추천 질문"
    }

    private func configureQuestionList() {
        questionList.axis = .vertical
        questionList.spacing = 8
        contentStack.addArrangedSubview(questionList)
    }

    private func renderQuestions() {
        questionList.arrangedSubviews.forEach {
            questionList.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (iconName, question) in questionSets[questionSetIndex] {
            questionList.addArrangedSubview(makeQuestionCard(iconName: iconName, question: question))
        }
    }

    @objc private func refreshQuestions() {
        questionSetIndex = (questionSetIndex + 1) % questionSets.count
        renderQuestions()
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
        picker.onAttachmentSelected = { [weak self] fileName, image in
            guard let self else { return }
            let preview = ChatAttachmentPreviewViewController(fileName: fileName, image: image)
            preview.onSend = { [weak self] in
                self?.navigationController?.pushViewController(
                    ChatConversationViewController(question: "첨부파일: \(fileName)"),
                    animated: true
                )
            }
            self.present(preview, animated: true)
        }
        picker.onLocationRequested = { [weak self] in
            guard let self else { return }
            let conversation = ChatConversationViewController(question: nil)
            self.navigationController?.pushViewController(conversation, animated: true)
            conversation.startLocationRequestFromHome()
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
