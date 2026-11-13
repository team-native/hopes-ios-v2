import UIKit

@MainActor
final class ChatHomeViewController: AppPageViewController {
    private var selectedDepartment = UserDefaults.standard.string(forKey: "chat.selectedDepartment") ?? "소프트웨어개발과"
    private let departmentButton = UIButton(type: .system)
    private let questions = [
        "학교에 입학하기 전에 준비하면 좋은 것은?",
        "전공 수업은 어떤 방식으로 진행되나요?",
        "기숙사 생활에서 가장 좋은 점은 무엇인가요?"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "채팅"
        addHeading("궁금한 점을 물어보세요", subtitle: "학과를 고르면 질문을 추천해드려요")

        addSection("학과")
        departmentButton.setTitle("학과 · \(selectedDepartment)     ⌄", for: .normal)
        departmentButton.setTitleColor(AppStyle.ink, for: .normal)
        departmentButton.contentHorizontalAlignment = .leading
        departmentButton.backgroundColor = .white
        departmentButton.layer.cornerRadius = 14
        departmentButton.layer.borderWidth = 1
        departmentButton.layer.borderColor = AppStyle.line.cgColor
        departmentButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        departmentButton.addAction(UIAction { [weak self] _ in self?.openDepartmentPicker() }, for: .touchUpInside)
        contentStack.addArrangedSubview(departmentButton)
        addRow("\(selectedDepartment) 선배 질문 보기", symbol: "chevron.right") { [weak self] in
            guard let self else { return }
            self.push(QuestionListViewController(category: self.selectedDepartment))
        }

        addSection("추천 질문")
        questions.forEach { question in
            addRow(question, symbol: "bubble.left") { [weak self] in
                self?.push(ChatConversationViewController(question: question))
            }
        }

        contentStack.addArrangedSubview(AppStyle.button("새 대화 시작", primary: true) { [weak self] in
            self?.push(ChatConversationViewController(question: nil))
        })
    }

    private func openDepartmentPicker() {
        let picker = DepartmentPickerViewController(selectedDepartment: selectedDepartment)
        picker.onSelect = { [weak self] department in
            guard let self else { return }
            self.selectedDepartment = department
            UserDefaults.standard.set(department, forKey: "chat.selectedDepartment")
            self.departmentButton.setTitle("학과 · \(department)     ⌄", for: .normal)
        }
        present(picker, animated: true)
    }
}

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
final class ChatConversationViewController: UIViewController, UITextFieldDelegate {
    private let initialQuestion: String?
    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let inputField = UITextField()

    init(question: String?) {
        initialQuestion = question
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "대화"
        view.backgroundColor = AppStyle.canvas
        configureMessages()
        configureComposer()

        if let initialQuestion {
            addMessage(initialQuestion, outgoing: true)
            addMessage("질문 고마워요!\n선배들의 답변을 준비하고 있어요. 실제 답변은 서비스 연결 후 표시됩니다.", outgoing: false)
        } else {
            addMessage("학교생활에 대해 궁금한 점을 편하게 물어보세요", outgoing: false)
        }
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
    }

    private func configureComposer() {
        let composer = UIStackView()
        composer.axis = .horizontal
        composer.spacing = 10
        composer.alignment = .center
        composer.backgroundColor = .white
        composer.isLayoutMarginsRelativeArrangement = true
        composer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        composer.translatesAutoresizingMaskIntoConstraints = false

        inputField.placeholder = "궁금한 내용을 입력해보세요"
        inputField.borderStyle = .roundedRect
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        let attach = UIButton(type: .system)
        attach.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        attach.tintColor = AppStyle.blue
        attach.widthAnchor.constraint(equalToConstant: 38).isActive = true
        attach.heightAnchor.constraint(equalToConstant: 42).isActive = true
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
                guard let self else { return }
                let location = ChatLocationViewController()
                location.onLocationSelected = { [weak self] value in
                    self?.addMessage("위치 첨부: \(value)", outgoing: true)
                }
                self.present(location, animated: true)
            }
            self.present(picker, animated: true)
        }, for: .touchUpInside)
        let send = UIButton(type: .system)
        send.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        send.tintColor = AppStyle.blue
        send.addAction(UIAction { [weak self] _ in self?.sendMessage() }, for: .touchUpInside)
        send.widthAnchor.constraint(equalToConstant: 42).isActive = true
        send.heightAnchor.constraint(equalToConstant: 42).isActive = true
        composer.addArrangedSubview(attach)
        composer.addArrangedSubview(inputField)
        composer.addArrangedSubview(send)
        view.addSubview(composer)

        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composer.topAnchor),
            inputField.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
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

    private func sendMessage() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        inputField.text = nil
        addMessage(text, outgoing: true)
        addMessage("질문을 기록했어요. 서비스 연결 후 선배의 답변을 받을 수 있어요.", outgoing: false)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
