import UIKit

@MainActor
final class CommunitySearchViewController: AppPageViewController, UITextFieldDelegate {
    private let searchField = UITextField()
    private let recentStack = UIStackView()
    private let recentChips = UIStackView()
    private let resultsStack = UIStackView()
    private var recentQueries = ["기숙사", "동아리 면접", "포트폴리오"]
    private var previousNavigationBarHidden = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(true, animated: animated)
        DispatchQueue.main.async { [weak self] in self?.searchField.becomeFirstResponder() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentStack.spacing = 16
        configureSearchField()
        contentStack.addArrangedSubview(makeSearchBar())
        contentStack.addArrangedSubview(makeRecentSearches())

        resultsStack.axis = .vertical
        resultsStack.spacing = 12
        resultsStack.isHidden = true
        contentStack.addArrangedSubview(resultsStack)
    }

    private func configureSearchField() {
        searchField.placeholder = "제목·내용 검색"
        searchField.font = .systemFont(ofSize: 15)
        searchField.textColor = AppStyle.ink
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self
        searchField.backgroundColor = .white
        searchField.layer.cornerRadius = 25
        searchField.layer.borderWidth = 1.5
        searchField.layer.borderColor = AppStyle.blue.withAlphaComponent(0.45).cgColor
        searchField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = AppStyle.muted
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 0, y: 0, width: 34, height: 20)
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 42, height: 32))
        icon.center = CGPoint(x: left.bounds.midX + 3, y: left.bounds.midY)
        left.addSubview(icon)
        searchField.leftView = left
        searchField.leftViewMode = .always
    }

    private func makeSearchBar() -> UIStackView {
        let cancel = UIButton(type: .system)
        cancel.setTitle("취소", for: .normal)
        cancel.setTitleColor(AppStyle.blue, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        cancel.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let row = UIStackView(arrangedSubviews: [searchField, cancel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        cancel.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func makeRecentSearches() -> UIStackView {
        let title = AppStyle.label("최근 검색어", size: 14, weight: .medium, color: AppStyle.muted)
        let clear = UIButton(type: .system)
        clear.setTitle("전체 삭제", for: .normal)
        clear.setTitleColor(AppStyle.muted, for: .normal)
        clear.titleLabel?.font = .systemFont(ofSize: 12)
        clear.addAction(UIAction { [weak self] _ in
            self?.recentQueries.removeAll()
            self?.renderRecentSearches()
        }, for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [title, UIView(), clear])
        header.axis = .horizontal
        header.alignment = .center

        recentChips.axis = .horizontal
        recentChips.spacing = 8
        recentChips.alignment = .leading
        recentStack.axis = .vertical
        recentStack.spacing = 12
        recentStack.addArrangedSubview(header)
        recentStack.addArrangedSubview(recentChips)
        renderRecentSearches()
        return recentStack
    }

    private func renderRecentSearches() {
        recentChips.arrangedSubviews.forEach { view in
            recentChips.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        recentQueries.forEach { query in
            let chip = UIButton(type: .system)
            chip.setTitle(query, for: .normal)
            chip.setTitleColor(AppStyle.muted, for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            chip.backgroundColor = .white
            chip.layer.cornerRadius = 19
            chip.layer.borderWidth = 1
            chip.layer.borderColor = AppStyle.line.cgColor
            chip.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
            chip.addAction(UIAction { [weak self] _ in
                self?.searchField.text = query
                self?.runSearch()
            }, for: .touchUpInside)
            recentChips.addArrangedSubview(chip)
        }
    }

    private func runSearch() {
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return }
        if !recentQueries.contains(query) { recentQueries.insert(query, at: 0) }
        renderRecentSearches()
        recentStack.isHidden = true
        resultsStack.isHidden = false
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
            post.title.lowercased().contains(normalizedQuery) || post.body.lowercased().contains(normalizedQuery)
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
