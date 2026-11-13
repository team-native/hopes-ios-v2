import UIKit

@MainActor
final class CommunitySearchViewController: AppPageViewController, UITextFieldDelegate {
    private let searchField = UITextField()
    private let resultsStack = UIStackView()
    private let suggestions = ["기숙사", "동아리", "취업"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "게시글 검색"
        addHeading("무엇이 궁금한가요?", subtitle: "커뮤니티 게시글을 검색해보세요")

        let searchRow = UIStackView()
        searchRow.axis = .horizontal
        searchRow.spacing = 8
        searchField.placeholder = "검색어를 입력하세요"
        searchField.borderStyle = .roundedRect
        searchField.returnKeyType = .search
        searchField.delegate = self
        let searchButton = UIButton(type: .system)
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .white
        searchButton.backgroundColor = AppStyle.blue
        searchButton.layer.cornerRadius = 12
        searchButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        searchButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        searchButton.addAction(UIAction { [weak self] _ in self?.runSearch() }, for: .touchUpInside)
        searchRow.addArrangedSubview(searchField)
        searchRow.addArrangedSubview(searchButton)
        contentStack.addArrangedSubview(searchRow)

        addSection("추천 검색어")
        let chips = UIStackView()
        chips.axis = .horizontal
        chips.spacing = 8
        suggestions.forEach { word in
            let chip = AppStyle.button("#\(word)") { [weak self] in
                self?.searchField.text = word
                self?.runSearch()
            }
            chips.addArrangedSubview(chip)
        }
        contentStack.addArrangedSubview(chips)

        addSection("게시글")
        resultsStack.axis = .vertical
        resultsStack.spacing = 12
        contentStack.addArrangedSubview(resultsStack)
        renderResults(for: "")
    }

    private func runSearch() {
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        renderResults(for: query)
        view.endEditing(true)
    }

    private func renderResults(for query: String) {
        resultsStack.arrangedSubviews.forEach { view in
            resultsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let normalizedQuery = query.lowercased()
        let posts = CommunityPostStore.shared.posts.filter { post in
            normalizedQuery.isEmpty || post.title.lowercased().contains(normalizedQuery) || post.body.lowercased().contains(normalizedQuery)
        }
        guard !posts.isEmpty else {
            resultsStack.addArrangedSubview(AppStyle.label("검색 결과가 없어요", size: 14, color: AppStyle.muted))
            return
        }
        posts.forEach { post in
            let row = AppStyle.button("\(post.title)\n\(post.grade) · \(post.time) · 댓글 \(post.comments)") { [weak self] in
                self?.push(CommunityPostDetailViewController(post: post))
            }
            row.contentHorizontalAlignment = .leading
            row.titleLabel?.numberOfLines = 2
            resultsStack.addArrangedSubview(row)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        runSearch()
        return true
    }
}
