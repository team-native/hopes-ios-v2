import UIKit

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
